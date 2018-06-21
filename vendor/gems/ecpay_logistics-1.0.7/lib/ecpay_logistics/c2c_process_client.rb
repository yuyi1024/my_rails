require "digest"
require "uri"
require "net/http"
require "net/https"
require "json"
require "date"
require "cgi"
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

    class C2CProcessClient

        def initialize
            @helper = ECpayLogistics::APIHelper.new
        end

        def updatestoreinfo(param)
            c2c_process_base_proc!(params: param)
            res = c2c_process_pos_proc!(params: param, apiname: 'UpdateStoreInfo')
            return res
        end

        def cancelc2corder(param)
            c2c_process_base_proc!(params: param)
            res = c2c_process_pos_proc!(params: param, apiname: 'CancelC2COrder')
            return res
        end

        def printunimartc2corderinfo(param)
            c2c_process_base_proc!(params: param)
            res = c2c_process_pos_proc!(params: param, apiname: 'PrintUniMartC2COrderInfo')
            return res
        end

        def printfamic2corderinfo(param)
            c2c_process_base_proc!(params: param)
            res = c2c_process_pos_proc!(params: param, apiname: 'PrintFAMIC2COrderInfo')
            return res
        end

        def printhilifec2corderinfo(param)
            c2c_process_base_proc!(params: param)
            res = c2c_process_pos_proc!(params: param, apiname: 'PrintHILIFEC2COrderInfo')
            return res
        end

        ### Private method definition start ###
        private

            def get_curr_unix_time()
                return Time.now.to_i
            end

            def c2c_process_base_proc!(params:)
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

            def c2c_process_pos_proc!(params:, apiname:)
                verify_c2c_process_api = ECpayLogistics::C2CProcessParamVerify.new(apiname)
                verify_c2c_process_api.verify_c2c_process_param(params)
                #encode special param
                sp_param = verify_c2c_process_api.get_special_encode_param(apiname)
                @helper.encode_special_param!(params, sp_param)

                # Insert chkmacval
                chkmac = @helper.gen_chk_mac_value(params, mode: 0)
                params['CheckMacValue'] = chkmac

                # gen post html
                api_url = verify_c2c_process_api.get_svc_url(apiname, @helper.get_op_mode)
                #post from server
                if apiname == 'UpdateStoreInfo' or apiname == 'CancelC2COrder'
                  resp = @helper.http_request(method: 'POST', url: api_url, payload: params)
                else
                  resp = @helper.gen_html_post_form(act: api_url, id: '_form_c2c', parameters: params)
                end

                # return  post response
                return resp
            end

        ### Private method definition end ###

    end
end
