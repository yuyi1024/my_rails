require 'carrierwave'
CarrierWave.configure do |config|
  config.fog_provider = 'fog/aws'
  config.fog_credentials = {
    provider:              'AWS', 
    aws_access_key_id:     ENV['aws_access_key_id'],
    aws_secret_access_key: ENV['aws_secret_access_key'],
    region:                'ap-northeast-1',         # optional, defaults to 'us-east-1'
    # host:                  '127.0.0.1',            # optional, defaults to nil
    # endpoint:              'http://127.0.0.1:3001' # optional, defaults to nil
  }
  config.fog_directory  = ENV['aws_bucket']                                     # required
  config.fog_public     = true                                                 # optional, defaults to true
  config.fog_attributes = {'Cache-Control'=>'max-age=315576000'} # optional, defaults to {}
end