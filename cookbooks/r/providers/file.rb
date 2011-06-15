action :install do

	package_name = ::File.basename(new_resource.package_name).gsub(/(.+)_[0-9.]*\.tar\.gz\z/,'\1')
	Chef::Log.info "Installing filesystem package #{package_name} from #{new_resource.package_name}"
	bash "R_file_package_install" do
		user "root"
		code <<-EOH
		set -e
		cat <<-EOF | R --no-save --no-restore -f -
		if (!("#{package_name}" %in% installed.packages())) {
			install.packages("#{new_resource.package_name}", repos=NULL)
			stopifnot("#{package_name}" %in% installed.packages())
		}
		EOF
		EOH
	end

end
