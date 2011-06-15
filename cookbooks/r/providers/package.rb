action :install do

	Chef::Log.info "Installing CRAN/BioC package #{new_resource.package_name}"
	bash "R_CRAN_BioC_package_install" do
		user "root"
		code <<-EOH
		set -e
		cat <<-EOF | R --no-save --no-restore -f -
		if (!("#{new_resource.package_name}" %in% installed.packages())) {
			source("http://bioconductor.org/biocLite.R") 
			biocLite("#{new_resource.package_name}")
			stopifnot("#{new_resource.package_name}" %in% installed.packages())
		} 
		EOF
		EOH
	end

end

action :remove do

	Chef::Log.info "Remove R package #{new_resource.package_name}"
	bash "R_package_remove" do
		user "root"
		code <<-EOH
		set -e
		cat <<-EOF | R --no-save --no-restore -f -
		package <- installed.packages()["#{new_resource.package_name}",]
		if (!is.na(package)) {
			remove.packages("#{new_resource.package_name}", package['LibPath'])
			stopifnot(!("#{new_resource.package_name}" %in% installed.packages()))
		}
		EOF
		EOH
	end


end