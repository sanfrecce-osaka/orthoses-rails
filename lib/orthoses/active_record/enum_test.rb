begin
  require 'test_helper'
rescue LoadError
end

module EnumTest
  LOADER1 = ->(){
    class User1 < ActiveRecord::Base
      enum :array, [ :array_active, :array_archived ]
      enum :map, { map_active: "active", map_archived: "archived" }
      enum :pref, [ :active, :archived ], prefix: true
      enum :suff, [ :active, :archived ], suffix: true
      enum :escape, [:"a-b-c", :"e_[]_f"]
    end
  }

  def test_enum(t)
    store = Orthoses::ActiveRecord::Enum.new(
      Orthoses::Store.new(LOADER1),
    ).call

    actual = store["EnumTest::User1"].to_rbs
    expect = <<~RBS
      class EnumTest::User1 < ::ActiveRecord::Base
        include EnumTest::User1::ActiveRecord_Enum_EnumMethods
        def self.arrays: () -> ActiveSupport::HashWithIndifferentAccess[String, Integer]
        type array_string = "array_active" | "array_archived"
        type array_symbol = :array_active | :array_archived
        def array: () -> array_string
        def array=: (array_string) -> void
                  | (array_symbol) -> void
                  | (0 | 1) -> void
        def self.maps: () -> ActiveSupport::HashWithIndifferentAccess[String, String]
        type map_string = "map_active" | "map_archived"
        type map_symbol = :map_active | :map_archived
        def map: () -> map_string
        def map=: (map_string) -> void
                | (map_symbol) -> void
                | ("active" | "archived") -> void
        def self.prefs: () -> ActiveSupport::HashWithIndifferentAccess[String, Integer]
        type pref_string = "active" | "archived"
        type pref_symbol = :active | :archived
        def pref: () -> pref_string
        def pref=: (pref_string) -> void
                 | (pref_symbol) -> void
                 | (0 | 1) -> void
        def self.suffs: () -> ActiveSupport::HashWithIndifferentAccess[String, Integer]
        type suff_string = "active" | "archived"
        type suff_symbol = :active | :archived
        def suff: () -> suff_string
        def suff=: (suff_string) -> void
                 | (suff_symbol) -> void
                 | (0 | 1) -> void
        def self.escapes: () -> ActiveSupport::HashWithIndifferentAccess[String, Integer]
        type escape_string = "a-b-c" | "e_[]_f"
        type escape_symbol = Symbol
        def escape: () -> escape_string
        def escape=: (escape_string) -> void
                   | (escape_symbol) -> void
                   | (0 | 1) -> void
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end

    actual = store["EnumTest::User1::ActiveRecord_Enum_EnumMethods"].to_rbs
    expect = <<~RBS
      module EnumTest::User1::ActiveRecord_Enum_EnumMethods
        def array_active?: () -> bool

        def array_active!: () -> bool

        def array_archived?: () -> bool

        def array_archived!: () -> bool

        def map_active?: () -> bool

        def map_active!: () -> bool

        def map_archived?: () -> bool

        def map_archived!: () -> bool

        def pref_active?: () -> bool

        def pref_active!: () -> bool

        def pref_archived?: () -> bool

        def pref_archived!: () -> bool

        def active_suff?: () -> bool

        def active_suff!: () -> bool

        def archived_suff?: () -> bool

        def archived_suff!: () -> bool

        def `a-b-c?`: () -> bool

        def `a-b-c!`: () -> bool

        def a_b_c?: () -> bool

        def a_b_c!: () -> bool

        def `e_[]_f?`: () -> bool

        def `e_[]_f!`: () -> bool

        def e___f?: () -> bool

        def e___f!: () -> bool
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end

  LOADER2 = ->(){
    class User2 < ActiveRecord::Base
      enum :array, %i[a b c d]
    end
  }

  def test_enum_unstrict(t)
    store = Orthoses::ActiveRecord::Enum.new(
      Orthoses::Store.new(LOADER2),
      strict_limit: 3,
    ).call

    actual = store["EnumTest::User2"].to_rbs
    expect = <<~RBS
      class EnumTest::User2 < ::ActiveRecord::Base
        include EnumTest::User2::ActiveRecord_Enum_EnumMethods
        def self.arrays: () -> ActiveSupport::HashWithIndifferentAccess[String, Integer]
        type array_string = String
        type array_symbol = Symbol
        def array: () -> array_string
        def array=: (array_string | array_symbol) -> void
                  | (Integer) -> void
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end

    actual = store["EnumTest::User2::ActiveRecord_Enum_EnumMethods"].to_rbs
    expect = <<~RBS
      module EnumTest::User2::ActiveRecord_Enum_EnumMethods
        def a?: () -> bool

        def a!: () -> bool

        def b?: () -> bool

        def b!: () -> bool

        def c?: () -> bool

        def c!: () -> bool

        def d?: () -> bool

        def d!: () -> bool
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
