#!/env/bin/ruby
# encoding: utf-8

class MmrzDBManager
  def initialize
    @db = SQLite3::Database.new "wordbook.db"
  end

  def createDB
    begin
      @db.execute "create table UNMMRZ(word char[255], pronounce char[255], memTimes int, remindTime int)"
    rescue Exception => e
    end
  end

  def insertDB row
    @db.execute "insert into UNMMRZ values(?, ?, ?, ?)", row
  end

  def updateDB row
    @db.execute "update UNMMRZ set memTimes = #{row[2]}, remindTime = #{row[3]} where word = '#{row[0]}'"
  end

  def readDB
    @db.execute "select * from UNMMRZ where memTimes < 8"
  end

  def closeDB
    @db.close
  end
end