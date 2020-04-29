if (length(lookup('classes', Array, 'unique', [])) > 1) {
  notify { 'Warning: Multiple role classes defined':
    message => 'In most cases, we should only use 1 single role class.'
  }
}

if (length(lookup('classes', Array, 'unique', [])) >= 1) {
  lookup('classes', Array, 'unique', []).include
}
else {
  notify { 'No role class defined':
    message => 'No role class defined, falling back to profile::undefined'
  }
  ['profile::undefined'].include
}
