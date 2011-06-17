require 'rubygems'
require 'chef'

# Adapted from Chef-generated Rakefile

Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

TOPDIR = File.expand_path(File.dirname(__FILE__))
PKGDIR = File.expand_path(File.join(TOPDIR, ".pkgs"))

load 'chef/tasks/chef_repo.rake'

# Clean out chef defined tasks we don't want or want to override
%w{ upload_cookbook upload_cookbooks install new_cookbook role roles ssl_cert 
		databag:create databag:create_item databag:upload databag:upload_all update }.each do |t|
	Rake.application.remove_task t
end

desc "Bundle cookbooks for distribution"
task :bundle_cookbooks => [ :metadata ]
task :bundle_cookbooks do
	tarball_name = "cookbooks.tar.gz"
	FileUtils.mkdir_p(PKGDIR)
	$tarball_path = File.join(PKGDIR, tarball_name)
	system("tar -X.gitignore -czvf #{$tarball_path} cookbooks")
end

desc "Upload cookbooks.tar.gz to github"
task :upload_cookbooks => [:bundle_cookbooks]
task :upload_cookbooks do
	# Adapted from upload command in https://github.com/tekkub/github-gem
	
	require 'rest-client'
	require 'nokogiri'
	require 'json'	

	repo  = 'chef-informatics-cookbooks'
	login = `git config github.user`.chomp 
	token = `git config github.token`.chomp

	begin
		res = RestClient.post "https://github.com/#{login}/#{repo}/downloads", {
			:file_size => File.size($tarball_path),
			:content_type => 'application/x-gzip',
			:file_name => File.basename($tarball_path),
			:description => 'Cookbooks',
			:login => login,
			:token => token
		}
		data = JSON.parse(res)
		res = RestClient.post "http://github.s3.amazonaws.com/", {
			:Filename => File.basename($tarball_path),
			:policy => data["policy"],
			:success_action_status => 201,
			:key => data["path"],
			:AWSAccessKeyId => data["accesskeyid"],
			:signature => data["signature"],
			:acl => data["acl"],
			"Content-Type" => 'application/x-gzip',
			:file => File.new($tarball_path, 'rb')
		}
		
	rescue RestClient::Exception => e
		if e.response.code == 422
			res = RestClient.get "https://github.com/#{login}/#{repo}/downloads", {
				:params => { :login => login, :token => token },
			}
			
			objs = Nokogiri::HTML(res).xpath('id("manual_downloads")/li').map do |fileinfo|
				{
					:id   => /\d+$/.match(fileinfo.at_xpath('a').attribute('href').text)[0],
					:name => fileinfo.at_xpath('descendant::h4/a').text
				}
			end
			objs = objs.select { |o| o[:name] == File.basename($tarball_path) }
			raise if objs.empty?
			
			RestClient.delete "https://github.com/#{login}/#{repo}/downloads/#{objs[0][:id]}", {
        :params => { "login" => login, "token" => token }
      }  do |response, request, result, &block|
				if response.code == 302  # Swallow the redirect
					response				
				else
					response.return!(request, result, &block)
				end
			end
			
			retry
		else
			p e.response.body
			raise e
		end	
	end

end
