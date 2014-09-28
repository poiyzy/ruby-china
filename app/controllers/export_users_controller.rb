class ExportUsersController < ApplicationController
  def index
    @users = User
    respond_to do |format|
      format.html
      format.csv { send_data @users.to_csv }
      format.xls # { send_data @products.to_csv(col_sep: "\t") }
    end
  end
end
