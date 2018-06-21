require "digest"
require "uri"
require "net/http"
require "net/https"
require "json"
require "cgi"
require "securerandom"
require "ecpay_logistics/helper"
require "ecpay_logistics/verification"
require "ecpay_logistics/error"
require "ecpay_logistics/core_ext/hash"
require "ecpay_logistics/core_ext/string"
# require "../../../gem/lib/ecpay_logistics/helper"
# require "../../../gem/lib/ecpay_logistics/verification"
# require "../../../gem/lib/ecpay_logistics/error"
# require "../../../gem/lib/ecpay_logistics/core_ext/hash"
# require "../../../gem/lib/ecpay_logistics/core_ext/string"

module ECpayLogistics

	class CreateClient
        include ECpayErrorDefinition

        def initialize
            @helper = ECpayLogistics::APIHelper.new
            @verify_create = ECpayLogistics::CreateParamVerify.new
        end

        def create(param)
            create_base_proc!(params: param)
            res = create_pos_proc!(params: param)
            return res
        end

        ### Private method definition start ###
        private

        def create_base_proc!(params:)
            if params.is_a?(Hash)
                # Transform param key to string
                params.stringify_keys()

								# Process PlatformID & MerchantID by contractor setting
			          if @helper.is_contractor?
			            params['PlatformID'] = @helper.get_mercid
			            if params['MerchantID'].nil?
			              raise "[MerchantID] should be specified when you're contractor-Platform."
			            end
			          else
			            params['PlatformID'] = ''
			            params['MerchantID'] = @helper.get_mercid
			          end

            else
                raise ECpayInvalidParam, "Recieved parameter object must be a Hash"
            end
        end

        def create_pos_proc!(params:)
            @verify_create.verify_create_param(params)
            #encode special param
            sp_param = @verify_create.get_special_encode_param('Create')
            @helper.encode_special_param!(params, sp_param)

            # Insert chkmacval
            chkmac = @helper.gen_chk_mac_value(params, mode: 0)
            params['CheckMacValue'] = chkmac
            # gen post html
            api_url = @verify_create.get_svc_url('Create', @helper.get_op_mode)
            #post from server
            resp = @helper.http_request(method: 'POST', url: api_url, payload: params)
            # return  post response
            return resp
        end

        ### Private method definition end ###

    end
end
