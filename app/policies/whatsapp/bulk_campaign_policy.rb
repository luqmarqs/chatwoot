class Whatsapp::BulkCampaignPolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  def send_campaign?
    @account_user.administrator?
  end

  def pause?
    @account_user.administrator?
  end

  def resume?
    @account_user.administrator?
  end

  def cancel?
    @account_user.administrator?
  end

  def export_csv?
    @account_user.administrator?
  end

  def import_recipients?
    @account_user.administrator?
  end

  def audience_preview?
    @account_user.administrator?
  end
end
