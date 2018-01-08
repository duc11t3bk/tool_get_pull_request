require "selenium-webdriver"
require "csv"

class SeleniumTest
  attr_reader :driver, :repository_path, :pull_requests, :wait, :data_export_to_csv, :csv_header

  def initialize
    @driver = Selenium::WebDriver.for :firefox
    @driver.navigate.to "https://github.com/login"
    @repository_path = "https://github.com/plataformatec/devise/pulls"
    @pull_requests = []
    @wait = Selenium::WebDriver::Wait.new timeout: 10
    @csv_header = ["Pull Request", "Line of code +", "Line of code -"]
    @data_export_to_csv = []
  end

  def execute
    login_github
    get_list_pull_requests repository_path
    count_total_additional
    export_data_to_csv "/home/framgia/Documents/Framgia/tai_lieu/Viblo/01_2018/tool_get_pull_request/result/result.csv"
  end

  private
  def login_github
    email = driver.find_element name: "login"
    email.send_keys ""

    password = driver.find_element name: "password"
    password.send_keys ""

    submit = driver.find_element name: "commit"
    submit.click
  end

  def get_list_pull_requests repository_path
    driver.get repository_path
    filters_by_months = [
      "is:pr is:merged NOT Merge in:title OR NOT Release in:title created:2017-01-01..2017-12-31"]
    filters_by_months.each do |month|
      filters_pull_request_by_query month
      sleep 5
      button_next = driver.find_element class: "next_page"
      while button_next
        link_pull_requests = driver.find_elements :xpath, "//a[@class='link-gray-dark no-underline h4 js-navigation-open']"

        puts link_pull_requests.size

        link_pull_requests.each do |link_pull_request|
          pull_requests << link_pull_request.attribute("href")
          puts link_pull_request.attribute("href")
        end
        break if button_next.tag_name == "span"
        button_next.click
        sleep 2
        button_next = driver.find_element class: "next_page"
      end
    end
    puts "\n"
    puts pull_requests
    puts pull_requests.size
  end

  def filters_pull_request_by_query query
    filter_element = driver.find_element id: "js-issues-search"
    filter_element.clear
    filter_element.send_keys query
    filter_element.submit
  end

  def count_total_additional
    total_additional = 0
    total_deletion = 0
    pull_requests.each do |pull_request|
      driver.get "#{pull_request}/files"
      wait.until {driver.find_element :xpath, '//*[@id="files_bucket"]/div[3]/div/span/span[1]'}
      additional_element = driver.find_element :xpath, '//*[@id="files_bucket"]/div[3]/div/span/span[1]'
      deletion_element = driver.find_element :xpath, '//*[@id="files_bucket"]/div[3]/div/span/span[2]'
      additional = additional_element.text.gsub(",", "").to_i
      deletion = deletion_element.text.gsub("−", "-").to_i
      data_export_to_csv << [pull_request, additional, deletion]
      total_additional += additional
      total_deletion += deletion
      puts "#{pull_request}  Line code +: #{additional}  Line code -: #{deletion}"
    end
    puts "total_additional : #{total_additional}"
    puts "total_deletion : #{total_deletion}"
  end

  def export_data_to_csv file_name
    CSV.open(file_name, "wb") do |csv|
      csv << csv_header
      data_export_to_csv.each do |data|
        csv << data
      end
    end

    puts "export csv success !"
  end
end

selenium_text = SeleniumTest.new
selenium_text.execute
