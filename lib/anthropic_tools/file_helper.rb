module AnthropicTools
  # Helper class for processing different file types
  class FileHelper
    # Process a file based on its extension
    # @param file [File, String] The file to process (can be a path or file object)
    # @return [String, Array, Hash] The processed file content
    def self.process_file(file)
      path = file.is_a?(String) ? file : file.path
      ext = File.extname(path).downcase
      
      case ext
      when '.txt', '.md', '.markdown'
        read_text_file(path)
      when '.json'
        read_json_file(path)
      when '.csv'
        read_csv_file(path)
      when '.pdf'
        read_pdf_file(path)
      when '.docx'
        read_docx_file(path)
      when '.xlsx', '.xls'
        read_excel_file(path)
      else
        raise ArgumentError, "Unsupported file type: #{ext}"
      end
    end
    
    # Read a plain text file
    # @param path [String] Path to the file
    # @return [String] File content
    def self.read_text_file(path)
      File.read(path)
    end
    
    # Read a JSON file
    # @param path [String] Path to the file
    # @return [Hash, Array] Parsed JSON content
    def self.read_json_file(path)
      require 'json'
      JSON.parse(File.read(path))
    end
    
    # Read a CSV file
    # @param path [String] Path to the file
    # @return [Array] Array of hashes representing each row
    def self.read_csv_file(path)
      require 'csv'
      data = []
      CSV.foreach(path, headers: true) do |row|
        data << row.to_h
      end
      data
    end
    
    # Read a PDF file
    # @param path [String] Path to the file
    # @return [String] Text content
    def self.read_pdf_file(path)
      begin
        require 'pdf-reader'
      rescue LoadError
        raise LoadError, "To read PDF files, add the 'pdf-reader' gem to your Gemfile"
      end
      
      reader = PDF::Reader.new(path)
      reader.pages.map(&:text).join("\n")
    end
    
    # Read a DOCX file
    # @param path [String] Path to the file
    # @return [String] Text content
    def self.read_docx_file(path)
      begin
        require 'docx'
      rescue LoadError
        raise LoadError, "To read DOCX files, add the 'docx' gem to your Gemfile"
      end
      
      doc = Docx::Document.open(path)
      doc.paragraphs.map(&:text).join("\n")
    end
    
    # Read an Excel file
    # @param path [String] Path to the file
    # @return [Array] Array of hashes representing each worksheet
    def self.read_excel_file(path)
      begin
        require 'roo'
      rescue LoadError
        raise LoadError, "To read Excel files, add the 'roo' gem to your Gemfile"
      end
      
      workbook = Roo::Spreadsheet.open(path)
      result = {}
      
      workbook.sheets.each do |sheet_name|
        sheet = workbook.sheet(sheet_name)
        headers = sheet.row(1)
        
        sheet_data = []
        (2..sheet.last_row).each do |i|
          row_data = {}
          sheet.row(i).each_with_index do |cell, j|
            row_data[headers[j]] = cell
          end
          sheet_data << row_data
        end
        
        result[sheet_name] = sheet_data
      end
      
      result
    end
  end
end
