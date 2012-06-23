module LogsHelper

# Given a date, generates the corresponding log entries for that
# date based on the /current/ schedule
def generate_log_entries(d=Date.today)
  n = 0
  Schedule.where(:day_of_week => d.wday).each{ |s|
    # don't insert a duplicate log entry if one already exists
    next if Log.where(:when => d, :schedule_id => s.id).length > 0
    # create each scheduled log entry for the given day
    log = Log.new{ |l|
      l.schedule = s
      l.volunteer = s.volunteer
      l.donor = s.donor
      l.recipient = s.recipient
      l.when = d
    }
    n += 1 if log.save
  }
  return n
end

# Sends an email to any volunteer who has a outstanding log entry
# from n or more days ago. Also sends an email to the admin summarizing
# all logs that have seen at least r reminders.
def send_reminder_emails(n=2,r=3)
  naughty_list = []
  n = 0
  Log.where(:weight => nil).each{ |l| 
    days_past = (Date.today - l.when).to_i
    #next unless days_past >= n
    l.num_reminders = 0 if l.num_reminders.nil?
    l.num_reminders += 1

    next if l.volunteer.nil?

    m = Notifier.volunteer_log_reminder(l)
    m.deliver
    n += 1

    l.save
    if l.num_reminders >= r
      naughty_list.push(l)
    end
  }
  if naughty_list.length > 0
    m = Notifier.admin_reminder_summary(naughty_list)
    puts m
    m.deliver
  end
  return n
end

end
