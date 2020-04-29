describe 'choco' do
  it 'has choco' do
    expect(command('choco -v').exit_status).to eq(0)
  end

  it 'has git' do
    expect(command('git --version').exit_status).to eq(0)
  end

  it 'has ruby' do
    expect(command('ruby --version').exit_status).to eq(0)
  end

  it 'has r10k' do
    expect(command('r10k version').exit_status).to eq(0)
  end

  it 'has right Puppet version' do
    expect(command('puppet --version').stdout).to match('5.5.19')
  end

  it 'has right id_rsa private key' do
    expect(file('C:\Users\vagrant\.ssh\id_rsa').content).to match('BEGIN RSA PRIVATE KEY')
    expect(file('C:\Users\vagrant\.ssh\id_rsa').content).to match('END RSA PRIVATE KEY')
  end

  it 'has right id_rsa public key' do
    expect(file('C:\Users\vagrant\.ssh\id_rsa.pub').content).to match('ssh-rsa')
  end

  it 'has github and bitbucket in known_hosts file' do
    expect(file('C:\Users\vagrant\.ssh\known_hosts').content).to match('github.com')
    expect(file('C:\Users\vagrant\.ssh\known_hosts').content).to match('bitbucket.org')
  end

end