require "digest"
require "uri"
require "net/http"
require "net/https"
require "json"
require "ecpay_payment/helper"
require "ecpay_payment/verification"
require "ecpay_payment/error"
require "ecpay_payment/core_ext/hash"
require "ecpay_payment/core_ext/string"
#require "helper"
#require "verification"
#require "error"
#require "core_ext/hash"
#require "core_ext/string"

module ECpayPayment

  class ECpayExecRefundAndGrant

    def initialize
      @helper = APIHelper.new
      #@verify_aiochkout = AioCheckOutParamVerify.new

    end

    def credit_do_act(param)
      act_base_proc!(params: param)
      res = act_pos_proc!(params: param, apiname: 'DoAction')
      return res
    end

    def aio_capture(param)
      act_base_proc!(params: param)
      res = act_pos_proc!(params: param, apiname: 'Capture')
      return res
    end

    ### Private method definition start ###
    private

      def act_base_proc!(params:)
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

      def act_pos_proc!(params:, apiname:)
        verify_query_api = ECpayPayment::ActParamVerify.new(apiname)
        verify_query_api.verify_act_param(params)
        #encode special param

        # Insert chkmacval
        chkmac = @helper.gen_chk_mac_value(params)
        params['CheckMacValue'] = chkmac
        # gen post html
        api_url = verify_query_api.get_svc_url(apiname, @helper.get_op_mode)
        #post from server
        resp = @helper.http_request(method: 'POST', url: api_url, payload: params)

        # return  post response
        return resp
      end

    ### Private method definition end ###

  end
end
