require 'assert'
require 'ardb/has_slug'

require 'ardb/record_spy'

module Ardb::HasSlug

  class UnitTests < Assert::Context
    desc "Ardb::HasSlug"
    setup do
      source_attribute = @source_attribute = Factory.string.to_sym
      slug_attribute   = @slug_attribute   = Factory.string.to_sym
      @record_class = Ardb::RecordSpy.new do
        include Ardb::HasSlug
        attr_accessor source_attribute, slug_attribute
        attr_reader :slug_db_column_name, :slug_db_column_value

        def update_column(name, value)
          @slug_db_column_name  = name
          @slug_db_column_value = value
        end
      end
    end
    subject{ @record_class }

    should have_imeths :has_slug
    should have_imeths :ardb_has_slug_config

    should "not have any has-slug configuration by default" do
      assert_equal({}, subject.ardb_has_slug_config)
    end

    should "set the record up to have a slug using `has_slug`" do
      subject.has_slug :source => @source_attribute

      assert_equal :slug, subject.ardb_has_slug_config[:attribute]
      assert_false subject.ardb_has_slug_config[:allow_underscores]

      value  = Factory.string
      record = subject.new.tap{ |r| r.send("#{@source_attribute}=", value) }
      assert_instance_of Proc, subject.ardb_has_slug_config[:source_proc]
      assert_equal value, record.instance_eval(&subject.ardb_has_slug_config[:source_proc])

      upcase_value = value.upcase
      assert_instance_of Proc, subject.ardb_has_slug_config[:preprocessor_proc]
      assert_equal value, subject.ardb_has_slug_config[:preprocessor_proc].call(upcase_value)

      validation = subject.validations.find{ |v| v.type == :presence }
      assert_not_nil validation
      assert_equal [subject.ardb_has_slug_config[:attribute]], validation.columns
      assert_equal :update, validation.options[:on]

      validation = subject.validations.find{ |v| v.type == :uniqueness }
      assert_not_nil validation
      assert_equal [subject.ardb_has_slug_config[:attribute]], validation.columns
      assert_equal true, validation.options[:case_sensitive]
      assert_nil validation.options[:scope]

      callback = subject.callbacks.find{ |v| v.type == :after_create }
      assert_not_nil callback
      assert_equal [:ardb_has_slug_generate_slug], callback.args

      callback = subject.callbacks.find{ |v| v.type == :after_update }
      assert_not_nil callback
      assert_equal [:ardb_has_slug_generate_slug], callback.args
    end

    should "allow passing custom options to `has_slug`" do
      allow_underscore = Factory.boolean
      unique_scope     = Factory.string.to_sym
      subject.has_slug({
        :attribute         => @slug_attribute,
        :source            => @source_attribute,
        :preprocessor      => :upcase,
        :allow_underscores => allow_underscore,
        :unique_scope      => unique_scope
      })

      assert_equal @slug_attribute,  subject.ardb_has_slug_config[:attribute]
      assert_equal allow_underscore, subject.ardb_has_slug_config[:allow_underscores]

      value = Factory.string.downcase
      assert_instance_of Proc, subject.ardb_has_slug_config[:preprocessor_proc]
      assert_equal value.upcase, subject.ardb_has_slug_config[:preprocessor_proc].call(value)

      validation = subject.validations.find{ |v| v.type == :uniqueness }
      assert_not_nil validation
      assert_equal unique_scope, validation.options[:scope]
    end

    should "raise an argument error if `has_slug` isn't passed a source" do
      assert_raises(ArgumentError){ subject.has_slug }
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @preprocessor      = [:downcase, :upcase, :capitalize].choice
      @allow_underscores = Factory.boolean
      @record_class.has_slug({
        :attribute         => @slug_attribute,
        :source            => @source_attribute,
        :preprocessor      => @preprocessor,
        :allow_underscores => @allow_underscores,
      })

      @record = @record_class.new

      # create a string that has mixed case and an underscore so we can test
      # that it uses the preprocessor and allow underscores options when
      # generating a slug
      @source_value = "#{Factory.string.downcase}_#{Factory.string.upcase}"
      @record.send("#{@source_attribute}=", @source_value)
    end
    subject{ @record }

    should "reset its slug using `reset_slug`" do
      subject.send("#{@slug_attribute}=", Factory.slug)
      assert_not_nil subject.send(@slug_attribute)
      subject.instance_eval{ reset_slug }
      assert_nil subject.send(@slug_attribute)
    end

    should "default its slug attribute using `ardb_has_slug_generate_slug`" do
      subject.instance_eval{ ardb_has_slug_generate_slug }

      exp = Slug.new(@source_value, {
        :preprocessor      => @preprocessor.to_proc,
        :allow_underscores => @allow_underscores
      })
      assert_equal exp,             subject.send(@slug_attribute)
      assert_equal @slug_attribute, subject.slug_db_column_name
      assert_equal exp,             subject.slug_db_column_value
    end

    should "slug its slug attribute value if set using `ardb_has_slug_generate_slug`" do
      @record.send("#{@slug_attribute}=", @source_value)
      # change the source attr to some random value, to avoid a false positive
      @record.send("#{@source_attribute}=", Factory.string)
      subject.instance_eval{ ardb_has_slug_generate_slug }

      exp = Slug.new(@source_value, {
        :preprocessor      => @preprocessor.to_proc,
        :allow_underscores => @allow_underscores
      })
      assert_equal exp,             subject.send(@slug_attribute)
      assert_equal @slug_attribute, subject.slug_db_column_name
      assert_equal exp,             subject.slug_db_column_value
    end

    should "not set its slug if it hasn't changed using `ardb_has_slug_generate_slug`" do
      generated_slug = Slug.new(@source_value, {
        :preprocessor      => @preprocessor.to_proc,
        :allow_underscores => @allow_underscores
      })
      @record.send("#{@slug_attribute}=", generated_slug)
      subject.instance_eval{ ardb_has_slug_generate_slug }

      assert_nil subject.slug_db_column_name
      assert_nil subject.slug_db_column_value
    end

  end

  class SlugTests < UnitTests
    desc "Slug"
    subject{ Slug }

    NON_WORD_CHARS = ((' '..'/').to_a + (':'..'@').to_a + ('['+'`').to_a +
                     ('{'..'~').to_a - ['-', '_']).freeze

    should have_imeths :new

    should "not change strings that are made up of valid chars" do
      string = Factory.string
      assert_equal string, subject.new(string)
      string = "#{Factory.string}-#{Factory.string.upcase}"
      assert_equal string, subject.new(string)
    end

    should "turn invalid chars into a seperator" do
      string = Factory.integer(3).times.map do
        "#{Factory.string(3)}#{NON_WORD_CHARS.choice}#{Factory.string(3)}"
      end.join(NON_WORD_CHARS.choice)
      assert_equal string.gsub(/[^\w]+/, '-'), subject.new(string)
    end

    should "allow passing a custom preprocessor proc" do
      string = "#{Factory.string}-#{Factory.string.upcase}"
      slug = subject.new(string, :preprocessor => :downcase.to_proc)
      assert_equal string.downcase, slug

      preprocessor = proc{ |s| s.gsub(/[A-Z]/, 'a') }
      slug = subject.new(string, :preprocessor => preprocessor)
      assert_equal preprocessor.call(string), slug
    end

    should "allow passing a custom seperator" do
      seperator = NON_WORD_CHARS.choice

      invalid_char = (NON_WORD_CHARS - [seperator]).choice
      string = "#{Factory.string}#{invalid_char}#{Factory.string}"
      slug = subject.new(string, :seperator => seperator)
      assert_equal string.gsub(/[^\w]+/, seperator), slug

      # it won't change the seperator in the strings
      string = "#{Factory.string}#{seperator}#{Factory.string}"
      assert_equal string, subject.new(string, :seperator => seperator)

      # it will change the default seperator now
      string = "#{Factory.string}-#{Factory.string}"
      slug = subject.new(string, :seperator => seperator)
      assert_equal string.gsub('-', seperator), slug
    end

    should "change underscores into its separator unless allowed" do
      string = "#{Factory.string}_#{Factory.string}"
      assert_equal string.gsub('_', '-'), subject.new(string)

      slug = subject.new(string, :allow_underscores => false)
      assert_equal string.gsub('_', '-'), slug

      assert_equal string, subject.new(string, :allow_underscores => true)
    end

    should "not allow multiple seperators in a row" do
      string = "#{Factory.string}--#{Factory.string}"
      assert_equal string.gsub(/-{2,}/, '-'), subject.new(string)

      # remove seperators that were added from changing invalid chars
      invalid_chars = (Factory.integer(3) + 1).times.map{ NON_WORD_CHARS.choice }.join
      string = "#{Factory.string}#{invalid_chars}#{Factory.string}"
      assert_equal string.gsub(/[^\w]+/, '-'), subject.new(string)
    end

    should "remove leading and trailing seperators" do
      string = "-#{Factory.string}-#{Factory.string}-"
      assert_equal string[1..-2], subject.new(string)

      # remove seperators that were added from changing invalid chars
      invalid_char = NON_WORD_CHARS.choice
      string = "#{invalid_char}#{Factory.string}-#{Factory.string}#{invalid_char}"
      assert_equal string[1..-2], subject.new(string)
    end

  end

end