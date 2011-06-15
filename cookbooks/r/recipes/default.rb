#
# Cookbook Name:: r
# Recipe:: default
#
# Copyright 2011, Michael Linderman
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node['platform']
when "ubuntu"
	include_recipe "apt"

	# Key obtained from CRAN Ubuntu README
	execute "gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && gpg -a --export E084DAB9 | sudo apt-key add -" do
		not_if "apt-key list | grep 'E084DAB9'"
		notifies :run, resources(:execute => "apt-get update"), :immediately
	end

	apt_repository "CRAN" do
		uri "http://lib.stat.cmu.edu/R/CRAN/bin/linux/ubuntu"
		distribution "#{node[:lsb][:codename]}/"
		action :add
	end

	%w{ r-base r-base-dev }.each do |p|
		package p do
			action :install
		end
	end
		
end

# Setup a default CRAN repository
# It would be better to make this a template, but we don't know the
# target directory until convergence time and so have to use this approach
bash "Set_R_site_profile" do
	user "root"
	code <<-EOH
	cat <<-EOF > $(R RHOME)/etc/Rprofile.site
	## Rprofile.site generated by Chef for #{node[:fqdn]}
	local({
		r <- getOption("repos")
		r["CRAN"] <- "#{node[:R][:CRAN][:default]}";
		options(repos = r)
	})
	EOF
	EOH
end