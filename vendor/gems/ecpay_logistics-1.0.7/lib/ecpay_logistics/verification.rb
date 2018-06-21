require "ecpay_logistics/error"
# require "../../../gem/lib/ecpay_logistics/error"
require "nokogiri"
require 'date'
module ECpayLogistics
    class LogisticsVerifyBase
        include ECpayErrorDefinition
        @@param_xml = Nokogiri::XML(File.open(File.join(File.dirname(__FILE__), 'ECpayLogistics.xml')))

        def get_svc_url(apiname, mode)
            url = @@param_xml.xpath("/ECpayLogistics/#{apiname}/ServiceAddress/url[@type=\"#{mode}\"]").text
            return url
        end

        def get_special_encode_param(apiname)
            ret = []
            node = @@param_xml.xpath("/ECpayLogistics/#{apiname}/Parameters//param[@urlencode=\"1\"]")
            node.each {|elem| ret.push(elem.attributes['name'].value)}
            return ret
        end

        def get_basic_params(apiname)
            basic_param = []
            @@param_xml.xpath("/ECpayLogistics/#{apiname}/Parameters/param[@require=\"1\"]").each do |elem|
                basic_param.push(elem.attributes['name'].value)
            end
            return basic_param
        end

        def get_cond_param(apiname)
            aio_sw_param = []
            conditional_param = {}
            @@param_xml.xpath("/ECpayLogistics/#{apiname}/Config/switchparam/n").each do |elem|
                aio_sw_param.push(elem.text)
            end
            aio_sw_param.each do |pname|
                opt_param = {}
                node = @@param_xml.xpath("/ECpayLogistics/#{apiname}/Parameters//param[@name=\"#{pname}\"]")
                node.xpath('./condparam').each do |elem|
                    opt = elem.attributes['owner'].value
                    params = []
                    elem.xpath('./param[@require="1"]').each do |pa|
                        params.push(pa.attributes['name'].value)
                    end
                    opt_param[opt] = params
                end
                conditional_param[pname] = opt_param
            end
            return conditional_param
        end

        def get_param_type(apiname)
            param_type = {}
            @@param_xml.xpath("/ECpayLogistics/#{apiname}/Parameters//param").each do |elem|
                param_type[elem.attributes['name'].value] = elem.attributes['type'].value
            end
            return param_type
        end

        def get_opt_param_pattern(apiname)
            pattern = {}
            node = @@param_xml.xpath("/ECpayLogistics/#{apiname}/Parameters//param[@type=\"Opt\"]")
            node.each do |param_elem|
                opt_elems = param_elem.xpath('./option')
                opt = []
                opt_elems.each{|oe|opt.push(oe.text)}
                pattern[param_elem.attributes['name'].value] = opt
            end
            return pattern
        end

        def get_int_param_pattern(apiname)
            pattern = {}
            node = @@param_xml.xpath("/ECpayLogistics/#{apiname}/Parameters//param[@type=\"Int\"]")
            node.each do |param_elem|
                mode = param_elem.xpath('./mode').text
                mx = param_elem.xpath('./maximum').text
                mn = param_elem.xpath('./minimal').text
                a = []
                [mode, mx, mn].each{|f|a.push(f)}
                pattern[param_elem.attributes['name'].value] = a
            end
            return pattern
        end

        def get_str_param_pattern(apiname)
            pattern = {}
            node = @@param_xml.xpath("/ECpayLogistics/#{apiname}/Parameters//param[@type=\"String\"]")
            node.each do |param_elem|
                p_name = param_elem.attributes['name'].value
                pat_elems = param_elem.xpath('./pattern')
                # if pat_elems.length > 1
                #     raise "Only 1 pattern tag is allowed for each parameter (#{p_name}) "
                # elsif pat_elems.length = 0
                #     raise "No pattern tag found for parameter (#{p_name}) "
                # end
                pat = pat_elems.text
                pattern[p_name] = pat
            end
            return pattern
        end

        def get_depopt_param_pattern(apiname)
            pattern = {}

            node = @@param_xml.xpath("/ECpayLogistics/#{apiname}/Parameters//param[@type=\"DepOpt\"]")
            node.each do |param_elem|
                parent_n_opts = {}
                sub_opts = {}
                p_name = param_elem.attributes['name'].value
                parent_name = param_elem.attributes['main'].value
                param_elem.xpath('./mainoption').each do |elem|
                    k = elem.attributes['name'].value
                    opt = []
                    elem.element_children.each{|c|opt.push(c.text)}
                    sub_opts[k] = opt
                end
                parent_n_opts[parent_name] = sub_opts
                pattern[p_name] = parent_n_opts
            end
            return pattern
        end

        def get_all_pattern(apiname)
            res = {}
            res['Type_idx'] = self.get_param_type(apiname)
            res['Int'] = self.get_int_param_pattern(apiname)
            res['String'] = self.get_str_param_pattern(apiname)
            res['Opt'] = self.get_opt_param_pattern(apiname)
            res['DepOpt'] = self.get_depopt_param_pattern(apiname)
            return res
        end

        def verify_param_by_pattern(params, pattern)
            type_index = pattern['Type_idx']
            params.keys.each do |p_name|
                p_type = type_index[p_name]
                patt_container = pattern[p_type]
                case
                when p_type == 'String'
                    regex_patt = patt_container[p_name]
                    mat = /#{regex_patt}/.match(params[p_name])
                    if mat.nil?
                        raise ECpayInvalidParam, "Wrong format of param #{p_name} or length exceeded."
                    end
                when p_type == 'Opt'
                    aval_opt = patt_container[p_name]
                    mat = aval_opt.include?(params[p_name])
                    if mat == false
                        raise ECpayInvalidParam, "Unexpected option of param #{p_name} (#{params[p_name]}). Avaliable option: (#{aval_opt})."
                    end
                when p_type == 'Int'
                    criteria = patt_container[p_name]
                    mode = criteria[0]
                    max = criteria[1].to_i
                    min = criteria[2].to_i
                    val = params[p_name].to_i
                    case
                    when mode == 'BETWEEN'
                        if val < min or val > max
                            raise ECpayInvalidParam, "Value of #{p_name} should be between #{min} and #{max} ."
                        end
                    when mode == 'GE'
                        if val < min
                            raise ECpayInvalidParam, "Value of #{p_name} should be greater than or equal to #{min}."
                        end
                    when mode == 'LE'
                        if val > max
                            raise ECpayInvalidParam, "Value of #{p_name} should be less than or equal to #{max}."
                        end
                    when mode == 'EXCLUDE'
                        if val >= min and val <= max
                            raise ECpayInvalidParam, "Value of #{p_name} can NOT be between #{min} and #{max} .."
                        end
                    else
                        raise "Unexpected integer verification mode for parameter #{p_name}: #{mode}. "
                    end
                when p_type == 'DepOpt'
                    dep_opt = patt_container[p_name]
                    parent_param = dep_opt.keys()[0]
                    all_dep_opt = dep_opt[parent_param]
                    parent_val = params[parent_param]
                    aval_opt = all_dep_opt[parent_val]
                    if aval_opt.nil? and pattern['Opt'][parent_param].include?(parent_val) == false
                        raise  ECpayInvalidParam, "Cannot find avaliable option of [#{p_name}] by related param [#{parent_param}](Value: #{parent_val})."
                    elsif aval_opt.is_a?(Array)
                        unless aval_opt.include?(params[p_name])
                            raise ECpayInvalidParam, "Unexpected option of param #{p_name} (#{params[p_name]}). Avaliable option: (#{aval_opt})."
                        end
                    end

                else
                    raise "Unexpected type (#{p_type}) for parameter #{p_name}. "

                end
            end
        end
    end

    class CreateParamVerify < LogisticsVerifyBase
        include ECpayErrorDefinition
        def initialize
            @logistics_basic_param = self.get_basic_params('Create').freeze
            @logistics_conditional_param = self.get_cond_param('Create').freeze
            @all_param_pattern = self.get_all_pattern('Create').freeze
        end

        def verify_create_param(params)
            if params.is_a?(Hash)
                #所有參數預設要全帶

                if params.has_value?(nil)
                    raise ECpayInvalidParam, %Q{Parameter value cannot be nil}
                end
                #1. 比對欄位是否缺乏
                if params['LogisticsType'].to_s == 'Home'
	                logistics_param_names = @logistics_conditional_param['LogisticsType']['Home']
	                p logistics_param_names
	                p params.keys()
                elsif params['LogisticsType'].to_s == 'CVS'
	                logistics_param_names = @logistics_conditional_param['LogisticsType']['CVS']
					        p logistics_param_names
                  p params.keys()
                else
	                raise ECpayInvalidParam, "['LogisticsType'] can not be #{params['LogisticsSubType'].to_s}"
                end
                param_diff = (logistics_param_names - params.keys()) - (@logistics_basic_param)
                p param_diff
                unless param_diff == []
                    raise ECpayInvalidParam, %Q{Lack required invoice param #{param_diff}}
                end
                unexp_param = (params.keys() - logistics_param_names) - (@logistics_basic_param)
                p unexp_param
                unless unexp_param == []
	                raise InvalidParam, %Q{Unexpected parameter in Invoice parameters #{unexp_param}}
                end

                #2. 比對特殊欄位值相依需求
                #a [ServerReplyURL]不可為空
                if params['ServerReplyURL'].to_s.empty?
	                raise ECpayLogisticsRuleViolate, "[ServerReplyURL] can not be empty."
                end

                #3 因應物流類型不同所對應的欄位，做相關檢查
                # [LogisticsType]為Home
                if params['LogisticsType'].to_s == 'Home'
	                # [LogisticsType]為Home => LogisticsSubType 不能不為TCAT and ECAN
	                unless params['LogisticsSubType'].to_s == 'TCAT' or params['LogisticsSubType'].to_s == 'ECAN'
		                raise ECpayLogisticsRuleViolate, "[LogisticsSubType] can not be '#{params['LogisticsSubType'].to_s}' when [LogisticsType] is Home."
	                end

	                # [LogisticsType]為Home => IsCollection 不能為Y
	                if params['IsCollection'].to_s == 'Y'
		                raise ECpayLogisticsRuleViolate, "[IsCollection] can not be '#{params['IsCollection'].to_s}' when [LogisticsType] is Home."
	                end

	                # [LogisticsType]為Home => SenderPhone and SenderCellPhone Can Not Both be empty
	                if params['SenderPhone'].to_s.empty? and params['SenderCellPhone'].to_s.empty?
		                raise ECpayLogisticsRuleViolate, "[SenderPhone] and [SenderCellPhone] can not both be empty when [LogisticsType] is Home."
	                end

	                # [LogisticsType]為Home => ReceiverPhone and ReceiverCellPhone Can Not Both be empty
	                if params['ReceiverPhone'].to_s.empty? and params['ReceiverCellPhone'].to_s.empty?
		                raise ECpayLogisticsRuleViolate, "[ReceiverPhone] and [ReceiverCellPhone] can not both be empty when [LogisticsType] is Home."
	                end

	                # [LogisticsType]為Home且[LogisticsSubType]為ECAN
	                if params['LogisticsSubType'].to_s == 'ECAN'
		                # [LogisticsSubType]為ECAN => Temperature 只能為0001常溫
        						unless params['Temperature'].to_s == '0001'
        		                    raise ECpayLogisticsRuleViolate, "[Temperature] can not be '#{params['Temperature'].to_s}' when [LogisticsSubType] is ECAN."
        						end
        						# [LogisticsSubType]為ECAN => ScheduledDeliveryTime 不能為5:20~21
        						if params['ScheduledDeliveryTime'].to_s == '5'
        							raise ECpayLogisticsRuleViolate, "[ScheduledDeliveryTime] can not be '#{params['ScheduledDeliveryTime'].to_s}' when [LogisticsSubType] is ECAN."
        						end
        						# [LogisticsSubType]為ECAN => PackageCount 範圍為1到999
        						if params['PackageCount'].to_i < 1 or params['PackageCount'].to_i > 999
        							raise ECpayLogisticsRuleViolate, "[PackageCount] of should be between 1 and 999 when [LogisticsSubType] is ECAN."
        						end

		              # [LogisticsType]為Home且[LogisticsSubType]為TCAT
	                elsif params['LogisticsSubType'].to_s == 'TCAT'
		                # [LogisticsSubType]為TCAT => ScheduledDeliveryTime 不能為12:9~17, 13:9~12&17~20, 23:13~20
		                if params['ScheduledDeliveryTime'].to_i >= 5 and params['ScheduleDeliveryTime'].to_i <= 23
			                raise ECpayLogisticsRuleViolate, "[ScheduledDeliveryTime] can not be '#{params['ScheduledDeliveryTime'].to_i}' when [LogisticsSubType] is TCAT."
		                end
		                # [LogisticsSubType]為TCAT => ScheduledDeliveryDate 參數無效
		                unless params['ScheduledDeliveryDate'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[ScheduledDeliveryDate] must be empty when [LogisticsSubType] is TCAT."
		                end
		                # [LogisticsSubType]為TCAT => PackageCount 參數無效
		                unless params['PackageCount'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[PackageCount] must be empty when [LogisticsSubType] is TCAT."
		                end
		                # [LogisticsSubType]為TCAT => ScheduledPickupTime 不可為空
		                if params['ScheduledPickupTime'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[ScheduledPickupTime] can not be empty when [LogisticsSubType] is TCAT."
		                end
	                end
	                # [Temperature]為0003冷凍 => Specification 不能為 0004:150cm
        					if params['Temperature'].to_s == '0003'
        						if params['Specification'].to_s == '0004'
        							raise ECpayLogisticsRuleViolate, "[Specification] can not be '#{params['Specification'].to_s}' when [Temperature] is 0003."
        						end
        					end
                end

                if params['LogisticsType'].to_s == 'CVS'
	                # [LogisticsType]為CVS => LogisticsSubType 不能為 HOME
	                if params['LogisticsSubType'].to_s == 'TCAT' or params['LogisticsSubType'].to_s == 'ECAN'
		                raise ECpayLogisticsRuleViolate, "[LogisticsSubType] can not be '#{params['LogisticsSubType'].to_s}' when [LogisticsType] is CVS."
		            # [LogisticsSubType]為UNIMART => UNIMART相關規則
	                elsif params['LogisticsSubType'].to_s == 'UNIMART'
				 	  # [LogisticsSubType]為UNIMART => ReceiverCellPhone Can Not be empty
						if params['ReceiverCellPhone'].to_s.empty?
							raise ECpayLogisticsRuleViolate, "[ReceiverCellPhone] can not be empty when [LogisticsSubType] is UNIMART."
						end

						# [LogisticsSubType]為UNIMART => ReturnStoreID Can Not be empty
						if params['ReceiverStoreID'].to_s.empty?
							raise ECpayLogisticsRuleViolate, "[ReceiverStoreID] can not be empty when [LogisticsSubType] is UNIMART."
						end

						# [LogisticsSubType]為UNIMART => ReturnStoreID Must be empty
						unless params['ReturnStoreID'].to_s.empty?
							raise ECpayLogisticsRuleViolate, "[ReturnStoreID] must be empty when [LogisticsSubType] is UNIMART."
						end

		            # [LogisticsSubType]為FAMI => FAMI相關規則
	                elsif params['LogisticsSubType'].to_s == 'FAMI'

		                # [LogisticsSubType]為FAMI => ReceiverCellPhone Can Not be empty
		                if params['ReceiverCellPhone'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[ReceiverCellPhone] can not be empty when [LogisticsSubType] is FAMI."
		                end

		                # [LogisticsSubType]為FAMI => ReturnStoreID Can Not be empty
		                if params['ReceiverStoreID'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[ReceiverStoreID] can not be empty when [LogisticsSubType] is FAMI."
		                end

		                # [LogisticsSubType]為FAMI => ReturnStoreID Must be empty
		                unless params['ReturnStoreID'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[ReturnStoreID] must be empty when [LogisticsSubType] is FAMI."
		                end

		            # [LogisticsSubType]為HILIFE => HILIFE相關規則
	                elsif params['LogisticsSubType'].to_s == 'HILIFE'

		                # [LogisticsSubType]為HILIFE => ReceiverPhone Can Not be empty
		                # if params['ReceiverPhone'].to_s.empty?
			              #   raise ECpayLogisticsRuleViolate, "[ReceiverPhone] can not be empty when [LogisticsSubType] is HILIFE."
		                # end

		                # [LogisticsSubType]為HILIFE => ReturnStoreID Can Not be empty
		                if params['ReceiverStoreID'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[ReceiverStoreID] can not be empty when [LogisticsSubType] is HILIFE."
		                end

		                # [LogisticsSubType]為HILIFE => ReturnStoreID Must be empty
		                unless params['ReturnStoreID'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[ReturnStoreID] must be empty when [LogisticsSubType] is HILIFE."
		                end

		            # [LogisticsSubType]為UNIMARTC2C => UNIMARTC2C相關規則
	                elsif params['LogisticsSubType'].to_s == 'UNIMARTC2C'

		                # [LogisticsSubType]為UNIMARTC2C => GoodsAmount must be equal CollectionAmount
		                unless params['GoodsAmount'].to_i == params['CollectionAmount'].to_i
			                raise ECpayLogisticsRuleViolate, "[GoodsAmount] '#{params['GoodsAmount'].to_i}' can not be equal [CollectionAmount] '#{params['CollectionAmount'].to_i}' when [LogisticsSubType] is UNIMARTC2C."
		                end

		                # [LogisticsSubType]為UNIMARTC2C => SenderCellPhone Can Not be empty
		                if params['SenderCellPhone'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[SenderCellPhone] can not be empty when [LogisticsSubType] is UNIMARTC2C."
		                end

		                # [LogisticsSubType]為UNIMARTC2C => ReceiverCellPhone Can Not be empty
		                if params['ReceiverCellPhone'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[ReceiverCellPhone] can not be empty when [LogisticsSubType] is UNIMARTC2C."
		                end

		                # [LogisticsSubType]為UNIMARTC2C => GoodsName Can Not be empty
		                if params['GoodsName'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[GoodsName] can not be empty when [LogisticsSubType] is UNIMARTC2C."
		                end

		                # [LogisticsSubType]為UNIMARTC2C => LogisticsC2CReplyURL Can Not be empty
		                if params['LogisticsC2CReplyURL'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[LogisticsC2CReplyURL] can not be empty when [LogisticsSubType] is UNIMARTC2C."
		                end

		                # [LogisticsSubType]為UNIMARTC2C => ReturnStoreID Can Not be empty
		                if params['ReceiverStoreID'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[ReceiverStoreID] can not be empty when [LogisticsSubType] is UNIMARTC2C."
		                end

		            # [LogisticsSubType]為FAMIC2C => FAMIC2C相關規則
	                elsif params['LogisticsSubType'].to_s == 'FAMIC2C'
						# [LogisticsSubType]為FAMIC2C => ReceiverCellPhone Cannot be empty
						if params['ReceiverCellPhone'].to_s.empty?
							raise ECpayLogisticsRuleViolate, "[ReceiverCellPhone] can not be empty when [LogisticsSubType] is FAMIC2C."
						end

		                # [LogisticsSubType]為FAMIC2C => ReturnStoreID Can Not be empty
		                if params['ReceiverStoreID'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[ReceiverStoreID] can not be empty when [LogisticsSubType] is FAMIC2C."
		                end

		            # [LogisticsSubType]為HILIFEC2C => HILIFEC2C相關規則
	                elsif params['LogisticsSubType'].to_s == 'HILIFEC2C'

		                # [LogisticsSubType]為HILIFEC2C => GoodsName Can Not be empty
		                if params['GoodsName'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[GoodsName] can not be empty when [LogisticsSubType] is HILIFEC2C."
		                end

		                # [LogisticsSubType]為HILIFEC2C => SenderCellPhone Can Not be empty
		                if params['SenderCellPhone'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[SenderCellPhone] can not be empty when [LogisticsSubType] is HILIFEC2C."
		                end

		                # [LogisticsSubType]為HILIFEC2C => ReceiverCellPhone Can Not be empty
		                if params['ReceiverCellPhone'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[ReceiverCellPhone] can not be empty when [LogisticsSubType] is HILIFEC2C."
		                end

		                # [LogisticsSubType]為HILIFEC2C => ReturnStoreID Can Not be empty
		                if params['ReceiverStoreID'].to_s.empty?
			                raise ECpayLogisticsRuleViolate, "[ReceiverStoreID] can not be empty when [LogisticsSubType] is HILIFEC2C."
		                end

	                end

                end

                #4 比對所有欄位Pattern
                self.verify_param_by_pattern(params, @all_param_pattern)

            else
                raise TypeError, "Recieved argument is not a hash"
            end
        end

    end

    class QueryParamVerify < LogisticsVerifyBase
        include ECpayErrorDefinition
        def initialize(apiname)
            @logistics_basic_param = self.get_basic_params(apiname).freeze
            @logistics_conditional_param = self.get_cond_param(apiname).freeze
            @all_param_pattern = self.get_all_pattern(apiname).freeze
        end

        def verify_query_param(params)
            if params.is_a?(Hash)
                param_diff = @logistics_basic_param - params.keys
                unless param_diff == []
                    raise ECpayInvalidParam, "Lack required param #{param_diff}"
                end

                #Verify Value pattern of each param
                self.verify_param_by_pattern(params, @all_param_pattern)

            else
                raise TypeError, "Recieved argument is not a hash"
            end

        end

        def verify_updateshipmentinfo_param(params)
            if params.is_a?(Hash)
                param_diff = @logistics_basic_param - params.keys
                unless param_diff == []
                    raise ECpayInvalidParam, "Lack required param #{param_diff}"
                end

                #2. 比對特殊欄位值相依需求
                #a [ShipmentDate] and [ReceiverStoreID] can not both be empty.
                if params['ShipmentDate'].to_s.empty? and params['ReceiverStoreID'].to_s.empty?
	                raise ECpayLogisticsRuleViolate, "[ShipmentDate] and [ReceiverStoreID] can not both be empty."
                end

                #Verify Value pattern of each param
                self.verify_param_by_pattern(params, @all_param_pattern)

            else
                raise TypeError, "Recieved argument is not a hash"
            end

        end
    end

    class ReturnParamVerify < LogisticsVerifyBase
        include ECpayErrorDefinition
        def initialize(apiname)
            @logistics_basic_param = self.get_basic_params(apiname).freeze
            @logistics_conditional_param = self.get_cond_param(apiname).freeze
            @all_param_pattern = self.get_all_pattern(apiname).freeze
        end

        def verify_returnhome_param(params)
            if params.is_a?(Hash)
                #預設參數要全帶

                if params.has_value?(nil)
                    raise ECpayInvalidParam, %Q{Parameter value cannot be nil}
                end
                #1. 比對欄位是否缺乏
                param_diff = @logistics_basic_param - params.keys()
                unless param_diff == []
                    raise ECpayInvalidParam, %Q{Lack required invoice param #{param_diff}}
                end

                #2. 比對特殊欄位值相依需求
                #a [AllPayLogisticsID] and [LogisitcsSubType] can not both be empty.
                if params['AllPayLogisticsID'].to_s.empty? and params['LogisticsSubType'].to_s.empty?
                  raise ECpayLogisticsRuleViolate, "[AllPayLogisticsID] and [LogisticsSubType] can not both be empty."
                end
                #b if [LogisticsSubType] isn't empty, it will chekcs info_params values can not be empty.
                info_params = ['SenderName', 'SenderZipCode', 'SenderAddress', 'ReceiverName', 'ReceiverZipCode', 'ReceiverAddress']
                if ['TCAT', 'ECAN'].include?(params['LogisticsSubType'].to_s)
                    info_params.each do |param_name|
                      # Check if there's empty value.
                      if params[param_name].to_s.empty?
                        raise ECpayLogisticsRuleViolate, "[#{param_name}] contains empty value."
                      end
                    end
                    unless /[\'\"]+/.match(params['GoodsName']).nil?
                      raise ECpayLogisticsRuleViolate, "[GoodsName] can not contains quotation marks"
                    end
                    if /^([\u4e00-\u9fa5]{1,5}|[a-zA-Z]{1,10})$/.match(params['SenderName']).nil? or /^([\u4e00-\u9fa5]{1,5}|[a-zA-Z]{1,10})$/.match(params['ReceiverName']).nil?
                      raise ECpayLogisticsRuleViolate, "[SenderName] or [ReceiverName] must be the most 5 Chinese alphabets or 10 English alphabets"
                    end
                    if /(^.{7,61}$)/.match(params['SenderAddress']).nil? or /(^.{7,61}$)/.match(params['ReceiverAddress']).nil?
                      raise ECpayLogisticsRuleViolate, "[SenderAddress] or [ReceiverAddress] must be 7 ~ 61 alphabets"
                    end
                    if /(^\d{3,5}$)/.match(params['SenderZipCode']).nil? or /(^\d{3,5}$)/.match(params['ReceiverZipCode']).nil?
                      raise ECpayLogisticsRuleViolate, "[SenderZipCode] or [ReceiverZipCode] must be 3 ~ 5 numbers"
                    end
  	                # [LogisitcsSubType]為TCAT or ECAN => SenderPhone and SenderCellPhone Can Not Both be empty
  	                if params['SenderPhone'].to_s.empty? and params['SenderCellPhone'].to_s.empty?
  		                raise ECpayLogisticsRuleViolate, "[SenderPhone] and [SenderCellPhone] can not both be empty when [LogisticsType] is Home."
  	                end

  	                # [LogisitcsSubType]為TCAT or ECAN => ReceiverPhone and ReceiverCellPhone Can Not Both be empty
  	                if params['ReceiverPhone'].to_s.empty? and params['ReceiverCellPhone'].to_s.empty?
  		                raise ECpayLogisticsRuleViolate, "[ReceiverPhone] and [ReceiverCellPhone] can not both be empty when [LogisticsType] is Home."
  	                end

  	                # [LogisticsSubType]為ECAN
  	                if params['LogisticsSubType'].to_s == 'ECAN'
  		                # [LogisticsSubType]為ECAN => Temperature 只能為0001常溫
          						unless params['Temperature'].to_s == '0001'
          		          raise ECpayLogisticsRuleViolate, "[Temperature] can not be '#{params['Temperature'].to_s}' when [LogisticsSubType] is ECAN."
          						end
          						# [LogisticsSubType]為ECAN => ScheduledDeliveryTime 不能為5:20~21
          						if params['ScheduledDeliveryTime'].to_s == '5'
          							raise ECpayLogisticsRuleViolate, "[ScheduledDeliveryTime] can not be '#{params['ScheduledDeliveryTime'].to_s}' when [LogisticsSubType] is ECAN."
          						end
          						# [LogisticsSubType]為ECAN => PackageCount 範圍為1到999
          						if params['PackageCount'].to_i < 1 or params['PackageCount'].to_i > 999
          							raise ECpayLogisticsRuleViolate, "[PackageCount] of should be between 1 and 999 when [LogisticsSubType] is ECAN."
          						end

  		              # [LogisticsSubType]為TCAT
  	                elsif params['LogisticsSubType'].to_s == 'TCAT'
  		                # [LogisticsSubType]為TCAT => ScheduledDeliveryTime 不能為12:9~17, 13:9~12&17~20, 23:13~20
  		                if params['ScheduledDeliveryTime'].to_i >= 5 and params['ScheduleDeliveryTime'].to_i <= 23
  			                raise ECpayLogisticsRuleViolate, "[ScheduledDeliveryTime] can not be '#{params['ScheduledDeliveryTime'].to_i}' when [LogisticsSubType] is TCAT."
  		                end
  		                # [LogisticsSubType]為TCAT => ScheduledDeliveryDate 參數無效
  		                unless params['ScheduledDeliveryDate'].to_s.empty?
  			                raise ECpayLogisticsRuleViolate, "[ScheduledDeliveryDate] must be empty when [LogisticsSubType] is TCAT."
  		                end
  		                # [LogisticsSubType]為TCAT => PackageCount 參數無效
  		                unless params['PackageCount'].to_s.empty?
  			                raise ECpayLogisticsRuleViolate, "[PackageCount] must be empty when [LogisticsSubType] is TCAT."
  		                end
  		                # [LogisticsSubType]為TCAT => ScheduledPickupTime 不可為空
  		                if params['ScheduledPickupTime'].to_s.empty?
  			                raise ECpayLogisticsRuleViolate, "[ScheduledPickupTime] can not be empty when [LogisticsSubType] is TCAT."
  		                end
  	                end
                    # [Temperature]為0003冷凍 => Specification 不能為 0004:150cm
          					if params['Temperature'].to_s == '0003'
          						if params['Specification'].to_s == '0004'
          							raise ECpayLogisticsRuleViolate, "[Specification] can not be '#{params['Specification'].to_s}' when [Temperature] is 0003."
          						end
          					end
                end


                #Verify Value pattern of each param
                self.verify_param_by_pattern(params, @all_param_pattern)

            else
                raise TypeError, "Recieved argument is not a hash"
            end

        end

        def verify_returncvs_param(params)
            if params.is_a?(Hash)
                #預設參數要全帶

                if params.has_value?(nil)
                    raise ECpayInvalidParam, %Q{Parameter value cannot be nil}
                end
                #1. 比對欄位是否缺乏
                param_diff = @logistics_basic_param - params.keys()
                unless param_diff == []
                    raise ECpayInvalidParam, %Q{Lack required invoice param #{param_diff}}
                end

                #2. 比對特殊欄位值相依需求
                # 商品名稱不可以有單引號跟雙引號
                unless /[\'\"]+/.match(params['GoodsName']).nil?
                  raise ECpayLogisticsRuleViolate, "[GoodsName] can not contains quotation marks"
                end
                item_params = ['GoodsName', 'Quantity', 'Cost']
                #商品名稱含有井字 => 認為是多樣商品 *GoodsName， *Quantity ，*Cost逐一用井字分割，計算數量後與第一個比對
                if params['GoodsName'].include?('#')
                    item_cnt = params['GoodsName'].split('#').length
                    item_params.each do |param_name|
                        # Check if there's empty value.
                        unless /(\#\#|^\#|\#$)/.match(params[param_name]).nil?
                            raise ECpayLogisticsRuleViolate, "[#{param_name}] contains empty value."
                        end
                        p_cnt = params[param_name].split('#').length
                        unless item_cnt == p_cnt
                            raise ECpayLogisticsRuleViolate, %Q{Count of item info [#{param_name}] (#{p_cnt}) not match item count from [ItemCount] (#{item_cnt})}
                        end
                    end

                else
                    #沒有管線 => 逐一檢查@item_params_list的欄位有無管線
                    item_params.each do |param_name|
                        if params[param_name].include?('#')
                            raise "Item info [#{param_name}] contains hash kay(#) delimiter but there's only one item in param [GoodsName]"
                        end
                    end
                end


                #Verify Value pattern of each param
                self.verify_param_by_pattern(params, @all_param_pattern)

            else
                raise TypeError, "Recieved argument is not a hash"
            end

        end

        def verify_returnhilifecvs_param(params)
            if params.is_a?(Hash)
                #預設參數要全帶

                if params.has_value?(nil)
                    raise ECpayInvalidParam, %Q{Parameter value cannot be nil}
                end
                #1. 比對欄位是否缺乏
                param_diff = @logistics_basic_param - params.keys()
                unless param_diff == []
                    raise ECpayInvalidParam, %Q{Lack required invoice param #{param_diff}}
                end

                #2. 比對特殊欄位值相依需求
                # 商品名稱不可以有單引號跟雙引號
                unless /[\'\"]+/.match(params['GoodsName']).nil?
                  raise ECpayLogisticsRuleViolate, "[GoodsName] can not contains quotation marks"
                end
                if /^([\u4e00-\u9fa5\w]{0,30}|[\w]{0,60})$/.match(params['GoodsName']).nil?
                  raise ECpayLogisticsRuleViolate, "[GoodsName] must be the most 30 Chinese alphabets or 60 English alphabets"
                end

                #Verify Value pattern of each param
                self.verify_param_by_pattern(params, @all_param_pattern)

            else
                raise TypeError, "Recieved argument is not a hash"
            end

        end

        def verify_returnunimartcvs_param(params)
            if params.is_a?(Hash)
                #預設參數要全帶

                if params.has_value?(nil)
                    raise ECpayInvalidParam, %Q{Parameter value cannot be nil}
                end
                #1. 比對欄位是否缺乏
                param_diff = @logistics_basic_param - params.keys()
                unless param_diff == []
                    raise ECpayInvalidParam, %Q{Lack required invoice param #{param_diff}}
                end

                #2. 比對特殊欄位值相依需求
                # 商品名稱不可以有單引號跟雙引號
                unless /[\'\"]+/.match(params['GoodsName']).nil?
                  raise ECpayLogisticsRuleViolate, "[GoodsName] can not contains quotation marks"
                end

                #Verify Value pattern of each param
                self.verify_param_by_pattern(params, @all_param_pattern)

            else
                raise TypeError, "Recieved argument is not a hash"
            end

        end

    end

    class C2CProcessParamVerify < LogisticsVerifyBase
        include ECpayErrorDefinition
        def initialize(apiname)
            @logistics_basic_param = self.get_basic_params(apiname).freeze
            @logistics_conditional_param = self.get_cond_param(apiname).freeze
            @all_param_pattern = self.get_all_pattern(apiname).freeze
        end

        def verify_c2c_process_param(params)
            if params.is_a?(Hash)
                #預設參數要全帶

                if params.has_value?(nil)
                    raise ECpayInvalidParam, %Q{Parameter value cannot be nil}
                end
                #1. 比對欄位是否缺乏
                param_diff = @logistics_basic_param - params.keys()
                unless param_diff == []
                    raise ECpayInvalidParam, %Q{Lack required invoice param #{param_diff}}
                end

                #2. 比對特殊欄位值相依需求
                # [ReceiverStoreID] and [ReturneStoreID] can not both be empty.
                if params.has_key?('ReceiverStoreID')
                    if params['ReceiverStoreID'].to_s.empty? and params['ReturneStoreID'].to_s.empty?
                        raise ECpayLogisticsRuleViolate, "[ReceiverStoreID] and [ReturneStoreID] can not both be empty."
                    end
                end
                #Verify Value pattern of each param
                self.verify_param_by_pattern(params, @all_param_pattern)

            else
                raise TypeError, "Recieved argument is not a hash"
            end

        end
    end
end
