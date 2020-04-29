# The 'role continuousconversation' class installs packages required for the continuousconversation role
class role::windows::iis {
  #include profile::windows::base
  include profile::windows::iis

  #Class['profile::windows::base']
  # -> 
  Class['profile::windows::iis']

}
