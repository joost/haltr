# -*- coding: utf-8 -*-
# == Schema Information
# Schema version: 20091016144057
#
# Table name: invoices
#
#  id                  :integer(4)      not null, primary key
#  client_id           :integer(4)
#  date                :date
#  number              :string(255)
#  extra_info          :text
#  terms               :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  discount_text       :string(255)
#  discount_percent    :integer(4)
#  draft               :boolean(1)
#  type                :string(255)
#  frequency           :integer(4)
#  invoice_template_id :integer(4)
#  status              :integer(4)      default(1)
#  due_date            :date
#  use_bank_account    :boolean(1)      default(TRUE)
#

# -*- coding: utf-8 -*-
class Invoice < ActiveRecord::Base

  unloadable
  
  # Invoice statuses
  STATUS_NOT_SENT = 1
  STATUS_SENT     = 5
  STATUS_CLOSED   = 9

  # Default tax %
  TAX = 18

  STATUS_LIST = { 'Not sent'=>STATUS_NOT_SENT,'Sent'=>STATUS_SENT,'Closed'=>STATUS_CLOSED}

  
  has_many :invoice_lines, :dependent => :destroy
  belongs_to :client
  validates_presence_of :client, :date
    
  def subtotal_without_discount
    total = Money.new(0)
    invoice_lines.each do |line|
      total = total + line.total 
    end
    total
  end
  
  def subtotal
    subtotal_without_discount - discount
  end
  
  def tax
    subtotal * (tax_percent / 100.0)
  end
  
  def discount
   
    if discount_percent
      subtotal_without_discount * (discount_percent / 100.0)
    else
      Money.new(0)
    end
  end
  
  def total
    subtotal + tax
  end
  
  def subtotal_eur
    "#{subtotal} €"    
  end

  def due
    if terms.nil? or terms==0
      "#{terms_description}: #{due_date}"
    else
      "#{terms_description}"
    end
  end
  
  def pdf_name
    # i18n catalan ca-AD
    # remove_non_ascii "factura-#{number.gsub('/','')}-#{client.name.upcase.gsub(/\/|\.|\'/,'').strip.gsub(' ','_')}.pdf"
    "factura-#{number.gsub('/','')}.pdf"
  end

  def recipients
    Person.find(:all,:order=>'last_name ASC',:conditions => ["client_id = ? AND invoice_recipient = ?", client, true])
  end
  
  def self.last_number
    i = InvoiceDocument.last :order => "number", :conditions => ["draft=?",false]
    i.number if i
  end
  
  def self.next_number
    number = self.last_number
    if number.nil?
      a = []
      num = 0
    else
      a = number.split('/')
      num = number.to_i
    end
    if a.size > 1
      a[1] =  sprintf('%03d', a[1].to_i + 1)
      return a.join("/")
    else
      return num + 1
    end
  end
  
  def sent?
    self.status > STATUS_NOT_SENT
  end

  def mark_closed
    update_attribute :status, STATUS_CLOSED
  end

  def mark_sent
    update_attribute :status, STATUS_SENT
  end

  def mark_not_sent
    update_attribute :status, STATUS_NOT_SENT
  end

  def closed?
    self.status == STATUS_CLOSED
  end

  
  def status_txt
    return "Not sent" if !sent?
    return "Sent" if sent?
  end
  
  def terms_description
    terms_object.description
  end
  
  # Sets due date
  def before_save
    self.due_date = terms_object.due_date
  end
  
  def payment_method
    if use_bank_account and client.bank_account
      ba = client.bank_account
      "Rebut domiciliat a #{ba[0..3]} #{ba[4..7]} ** ******#{ba[16..19]}"
    else
      ba = Setting.company_bank_account.to_s
      "Pagament per transferència al compte #{ba[0..3]} #{ba[4..7]} #{ba[8..9]} #{ba[10..19]}"
    end
    
  end
  
  private

  def terms_object
    Terms.new(self.terms, self.date)
  end

    
end
