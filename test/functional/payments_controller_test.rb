require File.dirname(__FILE__) + '/../test_helper'

class PaymentsControllerTest < ActionController::TestCase

  fixtures :invoices, :bank_infos

  def test_n19
    Haltr::TestHelper.fix_invoice_totals
    @request.session[:user_id] = 2
    get "n19", :id => invoices(:invoice1), :bank_account => "1234567890"
    assert_response :success
    assert_template 'payments/n19'
    assert_not_nil assigns(:due_date)
    assert_equal 'text/plain', @response.content_type
    lines = @response.body.chomp.split("\n")
    # spaces are relevant
    assert_equal '518077310000G000261113      COMPANY1                                                    12345678                                                                  ', lines[0]
    assert_equal '538077310000G000261113011208Company1                                12345678901234567890        01                                                                ', lines[1]
    assert_equal "568077310000G000B00000000   SOME NON'ASCII CHARS ?? LONG NAME THAT M114910865126953221150000092568                FRA 08/001                        925,68        ", lines[2]
  end

  def test_aeb43
    @request.session[:user_id] = 2
    get "import_aeb43_index", :project_id => 2 
    assert_response :success
    #TODO post "import_aeb43"
  end

end
