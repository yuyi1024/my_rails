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

	class ReturnClient
        include ECpayErrorDefinition

        def initialize
            @helper = ECpayLogistics::APIHelper.new
        end

        def returnhome(param)
            return_base_proc!(params: param)
            res = return_pos_proc!(params: param, apiname: 'ReturnHome')
            return res
        end

				def returncvs(param)
            return_base_proc!(params: param)
            res = return_pos_proc!(params: param, apiname: 'ReturnCVS')
            return res
        end

				def returnhilifecvs(param)
            return_base_proc!(params: param)
            res = return_pos_proc!(params: param, apiname: 'ReturnHiLifeCVS')
            return res
        end

				def returnunimartcvs(param)
            return_base_proc!(params: param)
            res = return_pos_proc!(params: param, apiname: 'ReturnUniMartCVS')
            return res
        end

        ### Private method definition start ###
        private

        def get_curr_unix_time()
            return Time.now.to_i
        end

        def return_base_proc!(params:)
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

        def return_pos_proc!(params:, apiname:)
            verify_return_api = ECpayLogistics::ReturnParamVerify.new(apiname)
						if apiname == 'ReturnHome'
							verify_return_api.verify_returnhome_param(params)
						elsif apiname == 'ReturnCVS'
							verify_return_api.verify_returncvs_param(params)
						elsif apiname == 'ReturnHiLifeCVS'
							verify_return_api.verify_returnhilifecvs_param(params)
						elsif apiname == 'ReturnUniMartCVS'
							verify_return_api.verify_returnunimartcvs_param(params)
						end
            #encode special param
            sp_param = verify_return_api.get_special_encode_param(apiname)
            @helper.encode_special_param!(params, sp_param)
            # Insert chkmacval
            chkmac = @helper.gen_chk_mac_value(params, mode: 0)
            params['CheckMacValue'] = chkmac
            # gen post html
            api_url = verify_return_api.get_svc_url(apiname, @helper.get_op_mode)
            #post from server
            resp = @helper.http_request(method: 'POST', url: api_url, payload: params)
            # return  post response
            return resp
        end

        ### Private method definition end ###

    end
end
