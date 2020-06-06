class ChangeDefaultBasicWorkTimeToUsers < ActiveRecord::Migration[5.1]
  def up
    change_column :users, :basic_work_time, :datetime, default: Time.current.change(hour: 8, min: 0, sec: 0)
    change_column :users, :designated_work_start_time, :datetime, default: Time.current.change(hour: 8, min: 30, sec: 0)
    change_column :users, :designated_work_end_time, :datetime, default: Time.current.change(hour: 17, min: 30, sec: 0)
  end
  
  def down
    change_column :users, :basic_work_time, :datetime
    change_column :users, :designated_work_start_time, :datetime
    change_column :users, :designated_work_end_time, :datetime
  end
end
