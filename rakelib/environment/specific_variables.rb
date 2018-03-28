module Environment
  class SpecificVariables

    PLATFORMTEST = {
        "management_account" => "445906556292",
        "gateway_services_account" => "853042650628",
        "client_workload1_account" => "930830869239",
        "trend_policy_id_linux" => "22",
        "trend_policy_id_windows" => "26"
    }

    NONPROD = {
        "management_account" => "906261169288",
        "gateway_services_account" => "761099892790",
        "client_workload1_account" => "300820918606",
        "trend_policy_id_linux" => "21",
        "trend_policy_id_windows" => "22"
    }

    PROD = {
        "management_account" => "281077040066",
        "gateway_services_account" => "395321653647",
        "client_workload1_account" => "719848509458",
        "trend_policy_id_linux" => "17",
        "trend_policy_id_windows" => "2"
    }

    def self.for(account_number)
      if ['281077040066', '395321653647', '719848509458'].include? account_number
        PROD
      elsif ['906261169288', '761099892790', '300820918606'].include? account_number
        NONPROD
      else
        PLATFORMTEST
      end
    end
  end
end