#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail
set -o xtrace
trap 'echo Setup return code: $?' 0
BASE_DIR=$(cd $(dirname $0); pwd -L)

THE_PWD=Super@Secret1

KEYTABS_DIR=/keytabs
REALM_NAME=METAL.ZNDX.ORG
IPA_ADMIN_PASSWORD=$THE_PWD
DIRECTORY_MANAGER_PASSWORD=$THE_PWD
CM_PRINCIPAL_PASSWORD=$THE_PWD
USER_PASSWORD=$THE_PWD

CM_PRINCIPAL=cloudera-scm

USERS_GROUP=cdp-users
ADMINS_GROUP=cdp-admins

function log_status() {
  local msg=$1
  echo "STATUS:$msg"
}

function get_group_id() {
  local group=$1
  ipa group-find --group-name="$group" | grep GID | awk '{print $2}'
}

function add_groups() {
  while [[ $# -gt 0 ]]; do
    group=$1
    shift 1
    ipa group-add "$group" || true
  done
}

function add_user() {
  local princ=$1
  local homedir=$2
  shift 2

  # Add user, set password and get keytab
  if ipa user-show "$princ" >/dev/null 2>&1; then
    echo "-- User [$princ] already exists"
  else
    echo "-- Creating user [$princ]"
    USERS_GRP_ID=$(get_group_id $USERS_GROUP)
    echo clouderatemp | ipa user-add "$princ" --first="$princ" --last="User" --cn="$princ" --homedir="$homedir" --noprivate --gidnumber $USERS_GRP_ID --password || true
    ipa group-add-member "$USERS_GROUP" --users="$princ" || true
    kadmin.local change_password -pw ${USER_PASSWORD} $princ
  fi
  mkdir -p "${KEYTABS_DIR}"
  echo -e "${USER_PASSWORD}\n${USER_PASSWORD}" | ipa-getkeytab -p "$princ" -k "${KEYTABS_DIR}/${princ}.keytab" --password
  chmod 444 "${KEYTABS_DIR}/${princ}.keytab"

  # Create a jaas.conf file
  cat > ${KEYTABS_DIR}/jaas-${princ}.conf <<EOF
KafkaClient {
  com.sun.security.auth.module.Krb5LoginModule required
  useKeyTab=true
  keyTab="${KEYTABS_DIR}/${princ}.keytab"
  principal="${princ}@${REALM_NAME}";
};
EOF

  # Add user to groups
  while [[ $# -gt 0 ]]; do
    group=$1
    shift 1
    ipa group-add-member "$group" --users="$princ" || true
  done
}

# authenticate as admin
echo "${IPA_ADMIN_PASSWORD}" | kinit admin >/dev/null

log_status "Creating groups"
add_groups $USERS_GROUP $ADMINS_GROUP shadow supergroup

log_status "Creating Cloudera Manager principal user and adding it to admins group"
add_user admin /home/admin admins $ADMINS_GROUP "trust admins" shadow supergroup

kinit -kt "${KEYTABS_DIR}/admin.keytab" admin
ipa krbtpolicy-mod --maxlife=3600 --maxrenew=604800 || true

log_status "Creating LDAP bind user"
add_user ldap_bind_user /home/ldap_bind_user

log_status "Adding required roles"
# Add this role to avoid racing conditions between multiple CMs coming up at the same time
ipa role-add cmadminrole || true
ipa role-add-privilege cmadminrole --privileges="Service Administrators" || true

log_status "Starting the IPA service"
systemctl restart krb5kdc
systemctl enable ipa

log_status "Configuring and starting rng-tools"
grep rdrand /proc/cpuinfo || echo 'EXTRAOPTIONS="-r /dev/urandom"' >> /etc/sysconfig/rngd
systemctl start rngd

log_status "Ensuring that SElinux is turned off now and at reboot"
setenforce 0 || true
sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

echo "Completed successfully: IPA"
log_status "IPA server installed successfully."

