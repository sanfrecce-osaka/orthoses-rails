require 'rbs'

stdlib_dependencies = %w[time monitor singleton logger mutex_m json date benchmark digest forwardable did_you_mean openssl socket]
gem_dependencies = %w[nokogiri]
rails_dependencies = %w[activesupport activemodel activejob activerecord]

VERSIONS.each do |version|
  namespace version do
    namespace :active_storage do
      export = "export/activestorage/#{version}"

      desc "export to #{export}"
      task :export do
        sh "rm -fr #{export}"
        sh "mkdir -p #{export}"

        # base
        sh "cp -a out/#{version}/active_storage.rbs #{export}"
        sh "cp -a out/#{version}/active_storage #{export}"
        sh "rm #{export}/active_storage/engine.rbs"
        decls = RBS::Parser.parse_signature(RBS::Buffer.new(
          content: File.read("out/#{version}/active_record/base.rbs"),
          name: "out/#{version}/active_record/base.rbs"
        )).map do |decl|
          decl.members.select! do |member|
            case member
            when RBS::AST::Members::Mixin
              member.name.to_s.include?("ActiveStorage")
            end
          end
          decl
        end
        File.open("#{export}/active_record_base.rbs", "w+") do |f|
          RBS::Writer.new(out: f).write(decls)
        end

        # TODO: remove after support action_controller
        sh "rm -fr #{export}/active_storage/blobs"
        sh "rm -fr #{export}/active_storage/representations"
        Dir.glob("#{export}/active_storage/*_controller.rbs").each do |controller|
          sh "rm -f #{controller}"
        end
        sh "rm -f #{export}/active_storage/streaming.rbs"

        generate_test_script(
          gem: :activestorage,
          version: version,
          export: export,
          stdlib_dependencies: stdlib_dependencies,
          gem_dependencies: gem_dependencies,
          rails_dependencies: rails_dependencies,
        )

        Pathname(export).join('_test').join('test.rb').write(<<~RUBY)
          class User < ActiveRecord::Base
            has_one_attached :one_image
            has_many_attached :many_image
          end

          user = User.new
          one = ActiveStorage::Attached::One.new("one_image", user)
          one.url
        RUBY

        Pathname(export).join('_test').join('test.rbs').write(<<~RBS)
          class User < ActiveRecord::Base
          end
        RBS
      end

      desc "validate version=#{version} gem=active_storage"
      task :validate do
        stdlib_opt = stdlib_dependencies.map{"-r #{_1}"}.join(" ")
        gem_opt = gem_dependencies.map{"-I ../../.gem_rbs_collection/#{_1}"}.join(" ")
        rails_opt = rails_dependencies.map{"-I export/#{_1}/#{version}"}.join(" ")
        sh "rbs #{stdlib_opt} #{gem_opt} #{rails_opt} -I #{export} validate --silent"
      end
    end
  end
end
