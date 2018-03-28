namespace 'git' do

  desc 'update tag'
  task :tag, [:tag] do |t, args|
    tag = args[:tag]

    `git push origin :refs/tags/#{tag} && git tag -fa #{tag} -m "update tag" && git push origin master --tags`
  end

end