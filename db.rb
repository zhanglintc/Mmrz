#!/env/bin/ruby
# encoding: utf-8

class MmrzDBManager
=begin
  table UNMMRZ:
  [0]word           -- char[255]
  [1]pronounce      -- char[255]
  [2]memTimes       -- int
  [3]remindTime     -- int
  [4]remindTimeStr  -- char[255]
  [5]wordID         -- int
=end

  def initialize
    @db = SQLite3::Database.new "wordbook.db"
  end

  def createDB
    begin
      @db.execute "create table UNMMRZ(word char[255], pronounce char[255], memTimes int, remindTime int, remindTimeStr char[255], wordID int)"
    rescue Exception => e
    end
  end

  def insertDB row
    @db.execute "insert into UNMMRZ values(?, ?, ?, ?, ?, ?)", row
  end

  def updateDB row
    @db.execute "update UNMMRZ set memTimes = #{row[2]}, remindTime = #{row[3]}, remindTimeStr = '#{row[4]}' where word = '#{row[0]}'"
  end

  def deleteDB wordID
    found = @db.execute("select * from UNMMRZ where wordID = #{wordID}").size != 0 ? true : false
    @db.execute "delete from UNMMRZ where wordID = #{wordID}"

    return found
  end

  def readDB
    @db.execute "select * from UNMMRZ where memTimes < 8"
  end

  def readAllDB
    @db.execute "select * from UNMMRZ"
  end

  def getMaxWordID
    # format of maxWordID is like: maxWordID = [[33]], thus use maxWordID[0][0] to access it
    @db.execute("select max(wordID) from UNMMRZ")[0][0] or 0
  end

  def closeDB
    @db.close
  end
end
