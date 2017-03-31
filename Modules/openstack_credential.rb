def openstack_credential(credential)
  # create credential string
  credential_str = ""
  credential_str += "OS_PROJECT_DOMAIN_NAME=" + credential['project_domain'] + " "
  credential_str += "OS_USER_DOMAIN_NAME=" + credential['user_domain'] + " "
  credential_str += "OS_PROJECT_NAME=" + credential['project'] + " "
  credential_str += "OS_USERNAME=" + credential['user'] + " "
  credential_str += "OS_PASSWORD=" + credential['password'] + " "
  credential_str += "OS_AUTH_URL=" + credential['auth_url'] + " "
  credential_str += "OS_IDENTITY_API_VERSION=" + credential['identity_api_version'].to_s + " "
  credential_str += "OS_IMAGE_API_VERSION=" + credential['image_api_version'].to_s + " "
  return credential_str
end
