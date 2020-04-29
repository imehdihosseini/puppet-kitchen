
windows_features_list = ['Web-WebServer', 'Web-Dyn-Compression', 'Web-Scripting-Tools', 'Web-Mgmt-Service',
    'Web-Mgmt-Tools', 'Web-Http-Redirect','File-Services','Web-Log-Libraries','Web-Request-Monitor','Web-IP-Security','Web-App-Dev']

windows_removed_features_list = ['Web-Dir-Browsing']

windows_features_list.each do |index|
    describe windows_feature(index) do
        it { should be_installed }
    end
end

windows_removed_features_list.each do |index|
    describe windows_feature(index) do
        it { should_not be_installed }
    end
end
