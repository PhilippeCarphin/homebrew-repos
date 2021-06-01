
source /fs/ssm/eccc/mrd/ordenv/profile/stable

domain=$1
ssmfile=$2

ssm_file=$2
package=${ssm_file%%.ssm}

ssm created -d ${domain}
ssm install -d ${domain} -f ${ssm_file}
ssm publish -d ${domain} -p ${package} -pp all
