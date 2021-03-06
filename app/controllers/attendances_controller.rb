class AttendancesController < ApplicationController
  before_action :set_one_month, except: [:working_now]



  def new #勤怠一覧画面
   @user = User.find(params[:user_id])
   @attendance_month_work = @user.attendances.new
  end
  
  
  def create #勤怠一覧画面 「出勤」「退勤」ボタン押下時処理
    @user = User.find(params[:user_id])
    @today = Date.current
    @attendance = @user.attendances.find_by(worked_on: params[:dayid])
    
      
    if @attendance.started_at.nil? 
      if @attendance.update_attribute(:started_at, Time.current)
        flash.now[:success] = "おはようございます"
        redirect_to new_user_attendance_path @user
      else
        flash[:danger] = "出勤登録失敗"
        render :new
      end
      
    elsif @attendance.finished_at.nil?
     
      started_at_check = @attendance.started_at
      started_at_range = started_at_check + 1.days
      tommorow_end_of_day = started_at_range.end_of_day
      tommorow_beginning_of_day = tommorow_end_of_day.beginning_of_day
      
      today_end_of_day = @attendance.started_at.end_of_day
      today_beginning_of_day = today_end_of_day.beginning_of_day
      
      if Time.current.between?(today_beginning_of_day,today_end_of_day)
        @attendance.tommorow = "0"
        
        if @attendance.update_attribute(:finished_at, Time.current)
          flash[:success] = "おつかれさまでした"
          redirect_to new_user_attendance_path @user
        else
          flash[:danger] = "退勤登録失敗1"
          render :new
        end
        
      elsif Time.current.between?(tommorow_beginning_of_day,tommorow_end_of_day)
        @attendance.tommorow = "1"
        
        if @attendance.update_attribute(:finished_at, Time.current)
          
          flash[:success] = "おつかれさまでした"
          redirect_to new_user_attendance_path @user
        else
          flash[:danger] = "退勤登録失敗2"
          render :new
        end
        
      else
        flash[:danger] = "退勤登録に失敗しました。出社日時の翌日までの範囲が有効です。編集画面で正しい退勤時間を登録してください。"
        render :new
      end
    
    end
    
  end
  
  
  def month_confirmation_create #勤怠一覧画面 右下 1ヶ月分の勤怠申請ボタン 押下時処理
    if params[:attendance][:month_work_who_consent].present?
      @user = User.find(params[:user_id])
      first_day = params[:dayid]
      first_day = first_day.to_date
       
      last_day = first_day.end_of_month
      attendance_month = @user.attendances.where(worked_on: first_day..last_day)
      
      attendance_month.each do |item|
        attendance = Attendance.find_by(id: item.id)
    
        attendance[:month_work_who_consent] = params[:attendance][:month_work_who_consent]
        attendance[:month_work] = 0
      
        if attendance.save!
          flash[:success] = "1ヶ月分勤怠の承認申請を送信しました。"

        else
          flash[:danger] = "1ヶ月分勤怠の承認申請を送信できませんでした。"
          render :new
        end
      end
    end 
    
  end
  

  
  def edit #勤怠編集画面
    @attendance = @user.attendances.find_by(user_id: current_user.id)
  end
  

 

  
  def update_waiting # 勤怠編集画面　送信処理
    @user = User.find(params[:user_id])

    attendance_edit_params.each do |id, item|
      if item[:who_consent].present?
          attendance = Attendance.find(id)
          
          year = attendance[:worked_on].year
          month = attendance[:worked_on].month
          
          
          at_after_started_at = Time.new(year.to_i, month.to_i, item["after_started_at(3i)"].to_i, item["after_started_at(4i)"].to_i, item["after_started_at(5i)"].to_i)
          at_after_finished_at = Time.new(year.to_i, month.to_i, item["after_finished_at(3i)"].to_i, item["after_finished_at(4i)"].to_i, item["after_finished_at(5i)"].to_i)
          
          attendance[:after_started_at] = at_after_started_at.to_datetime
          attendance[:after_finished_at] = at_after_finished_at.to_datetime
  
         
          
          attendance[:request_at] = Time.current
          attendance[:request_type] = 1
          attendance[:request_status] = 0
        
          attendance[:before_started_at] = attendance[:started_at]
          attendance[:before_finished_at] = attendance[:finished_at]
          
        
          
          
          attendance[:who_consent] = item[:who_consent]
      
          attendance[:tommorow_flag] = item[:tommorow_flag]
          
          unless attendance[:before_started_at] == attendance[:after_started_at] && attendance[:after_finished_at] == attendance[:before_finished_at]
            attendance.update_attributes!(update_waiting_parmas)
          end
      end   
    end
      
  

      flash[:success] = "勤怠変更を申請しました。承認までしばらくお待ちください。"
      redirect_to new_user_attendance_url
  end
  
  
  def edit_confirm #勤怠変更の承認画面
  
    @attendance = Attendance.where(who_consent: current_user.id)
    @attendance_user_id = @attendance.pluck(:user_id)
    @user = User.new
   
    @users = {}
    @attendance_user_id.each do |user_id|
      @user = User.find_by(id: user_id)
      @user_attendance = @user.attendances.where(who_consent: current_user.id).where(request_status: 0).where(request_type: 1).to_a
      
      @users.merge!(user_id => @user_attendance)
    end
    

  end
  
  def update #勤怠変更承認時の処理
    update_edit_params.each do |id, item|
        
        if item[:ok_flag] == "1" && item[:request_status] == "1"
    
          attendance = Attendance.find_by(id: id)
          @user = User.find_by(id: attendance.user_id)
          @new_attendance = @user.attendances.new
            
              @new_attendance[:started_at] = attendance.after_started_at
              @new_attendance[:finished_at] = attendance.after_finished_at
              @new_attendance[:before_started_at] = attendance.before_started_at
              @new_attendance[:before_finished_at] = attendance.before_finished_at
              @new_attendance[:who_consent] = attendance.who_consent
              @new_attendance[:request_at] = Time.current
        
              @new_attendance[:worked_on] = attendance[:worked_on]
              @new_attendance[:note] = attendance.note
              @new_attendance[:request_type] = attendance.request_type
              @new_attendance[:request_status] = 1
             
              at_after_tommorow_flag = attendance[:tommorow_flag]
       
              if attendance[:tommorow].present?
                @new_attendance[:tommorow_flag] = attendance[:tommorow]
              end
              
              @new_attendance[:tommorow] = at_after_tommorow_flag
              @new_attendance[:only_day] = 1
         
              @new_attendance.save!

              attendance[:started_at] = attendance[:after_started_at]
              attendance[:finished_at] = attendance[:after_finished_at]
              attendance[:request_at] = Time.current
              attendance[:request_type] = attendance.request_type
              attendance[:only_day] = nil
              attendance[:request_status] = "3"
              attendance.save!
         
          
            
        end
        
        
    end
    flash.now[:success] = "勤怠情報の変更が完了しました"
    redirect_to new_user_attendance_path
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = "勤怠情報の変更が完了していません。"
    redirect_to new_user_attendance_path
  end
  
  
  
  def attendance_log #勤怠変更ログ画面
    @user = User.find(current_user.id)
    
      if params[:worked_on_between].present?
        @search_date = Time.new(params[:worked_on_between][:"date(1i)"].to_i, params[:worked_on_between][:"date(2i)"].to_i, params[:worked_on_between][:"date(3i)"].to_i)
      end
    

    
    @attendance = @user.attendances.order(:created_at).where("(request_status = ?)", "3").where("only_day is null").search(@search_date)
   
    @attendance_default = @attendance.pluck(:worked_on).first
    
  end
  
  def overwork #残業申請 画面
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find_by(id: params[:id])
  end
  

  def overwork_update #残業申請 送信処理
    @user = User.find(params[:user_id])
    attendance = Attendance.find(params[:id])
    
    year = attendance.worked_on.year
    month = attendance.worked_on.month
  
    attendance.after_finished_at = Time.new(year.to_i, month.to_i, params[:attendance]["after_finished_at(3i)"].to_i, params[:attendance]["after_finished_at(4i)"].to_i, params[:attendance]["after_finished_at(5i)"].to_i)
    attendance.after_finished_at.to_datetime
    attendance.request_at = Time.current
    attendance.request_type = 2
    attendance.request_status = 0
    attendance.before_finished_at = attendance.finished_at
    attendance.before_started_at = attendance.started_at
    attendance.tommorow_flag = params[:attendance][:tommorow_flag]
    
    if attendance.save
      flash[:success] = "残業申請を送信しました"
      redirect_to new_user_attendance_path
    else
      flash[:danger] = "残業申請を送信できませんでした"
      render :overwork
    end
    
  end
  
  def overwork_confirm #残業申請 承認画面
    @user = User.find(params[:user_id])
    @attendance = Attendance.where(who_consent: current_user.id).where(request_status: 0).where(request_type: 2).to_a
    @attendance_user_id = @attendance.pluck(:user_id)
    @user_new = User.new
    
    @users = {}
    @attendance_user_id.each do |user_id|
    
      @user_new = User.find_by(id: user_id)
      @user_attendance = @user_new.attendances.where(who_consent: current_user.id).where(request_status: 0).where(request_type: 2).to_a
      
      @users.merge!(user_id => @user_attendance)
    end
  end
  
  def overwork_confirm_update #残業申請 承認処理
   
    update_overwork_edit_params.each do |id, item|
  
          attendance = Attendance.find_by(id: id)
          @user = User.find_by(id: attendance.user_id)
 
        if item[:request_status] == "1"
          
        
          @new_attendance = @user.attendances.new
        
          @new_attendance.started_at = attendance.before_started_at
          
          year = attendance[:worked_on].year
          month = attendance[:worked_on].month
          
          
          at_after_finished_at = Time.new(year.to_i, month.to_i, item["after_finished_at(3i)"].to_i, item["after_finished_at(4i)"].to_i, item["after_finished_at(5i)"].to_i)
          
         
          @new_attendance.finished_at = at_after_finished_at
          @new_attendance.who_consent = attendance.who_consent
          @new_attendance.worked_on = attendance[:worked_on]
          @new_attendance.note = attendance.note
          @new_attendance.request_type = attendance.request_type
          @new_attendance.request_status = 1
          @new_attendance.tommorow = item[:tommorow_flag]
          @new_attendance.only_day = 1
          
          @new_attendance.before_started_at = attendance.started_at
          @new_attendance.before_finished_at = attendance.finished_at
          @new_attendance.tommorow_flag = attendance.tommorow
          
          attendance.started_at = attendance.after_started_at
          attendance.finished_at = attendance.after_finished_at
          attendance.request_at = Time.current
          attendance.request_status = "3"
          attendance.only_day = nil
   
          attendance.save!
  
          if @new_attendance.save!
            flash.now[:success] = "勤怠情報の変更が完了しました"
            redirect_to new_user_attendance_path
           
          else
            flash.now[:danger] = "勤怠情報の変更が完了していません。"
            redirect_to overwork_confirm_user_attendances_path
          end 
        elsif item[:request_status] == "2"

          attendance.after_started_at = nil
          attendance.after_finished_at = nil
          attendance.before_started_at = nil
          attendance.before_finished_at = nil
          attendance.request_at = nil
          attendance.request_type = nil
          attendance.only_day = nil
          attendance.tommorow_flag = nil
          attendance.request_status = 2
          attendance.save!
          
          redirect_to new_user_attendance_path
          flash.now[:success] = "変更しました"
        
        end

    end
  end
  
  def month_confirmation #1ヶ月分の勤怠 承認画面
      @attendance_month = Attendance.where(month_work_who_consent: current_user.id).where(month_work: 0)
      @attendance_user_id = @attendance_month.pluck(:user_id)
      @user = User.new
     
      @users = {}
      @attendance_user_id.each do |user|
        @user = User.find_by(id: user)
        @user_attendance = @user.attendances.where(month_work_who_consent: current_user.id).where(month_work: 0).first

        
        @users.merge!(user => @user_attendance)
      end
  end
  
  def month_confirmation_update #1ヶ月分の勤怠承認処理
  
    
    update_month_edit_params.each do |key, item|
     
      
      if item[:month_work] == "1" && item[:ok_flag] == "1"
        @attendance_month = Attendance.find_by(id: key)
        @user = User.find_by(id: @attendance_month.user_id)
        @month_start = @attendance_month.worked_on.beginning_of_month
        @month_end = @month_start.end_of_month
        @month = @user.attendances.where(worked_on: @month_start..@month_end)
        @month.each do | day |
          
          attendance = Attendance.find(day.id)
          
          attendance.month_work = 1
          
     
          
          if attendance.save!
            flash[:success] = "勤怠の承認が完了しました"
            redirect_to new_user_attendance_path(current_user)
          else
            flash[:danger] = "勤怠の承認処理中にエラーが発生しました"
            render :month_confirmation
          end
          
        end
      end
      
    
    end
    

  end
  
  def working_now # 現在出勤中の社員一覧
    @attendance = Attendance.where.not(started_at: nil).where(finished_at: nil)
    @attendance_user_id = @attendance.pluck(:user_id).uniq
    
    @users = {}
    @attendance_user_id.each do |user_id|
    
      user = User.find(user_id)
      @users.merge!(user.id => user.name)
      
    end
  end
 
  def work_basic_edit
  
  end
 
 
  def destroy
  end
  
  
  private
  
    def attendance_edit_params
      params.require(:user).permit(attendances: [:worked_on, :after_started_at, :after_finished_at, :note, :who_consent, :tommorow_flag])[:attendances]
    end
    
    def update_edit_params
      params.require(:user).permit(attendances: [:worked_on, :request_status, :ok_flag, :only_day, :tommorow])[:attendances]
    end
    
    def overwork_edit_params
      params.permit(:after_finished_at, :tommorow_flag, :note, :who_consent)
    end
    
    def update_overwork_edit_params
      params.require(:user).permit(attendances: [:worked_on, :after_finished_at, :request_status, :tommorow, :tommorow_flag])[:attendances]
    end
    
    def update_month_edit_params
      params.require(:user).permit(attendances: [:month, :month_work, :ok_flag])[:attendances]
    end
    
    def update_waiting_parmas #勤怠編集画面更新時 承認待ちにするカラムの処理
      params.permit(:after_started_at, :after_finished_at, :request_at, :request_type, :request_status, :before_started_at, :before_finished_at, :who_consent, :tommorow_flag)
    end

  
end
