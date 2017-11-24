########################################################
# Defines the main methods that are necessary to trim vectors sequences
########################################################

class PluginVectors < Plugin

  #Returns an array with the errors due to parameters are missing 
       def check_params

        #Priority, base ram
             cores = [1]
             priority = 2
             ram = [100]
             base_ram = 720 #mb
        #Array to store errors        
             errors=[]    
        #Check params (errors,param_name,param_class,default_value,comment) 
             @params.check_param(errors,'vectors_trimming_position','String','both','Trim vectors in which position: right, left or both (default)')
             #if plugins trims reads in both tips, double the requirements
             if @params.get_param('vectors_trimming_position') == 'both'
                     cores << 1
                     ram << 100
             end 

             @params.check_param(errors,'vectors_db','DB','vectors','Sequences of vectors to use in trimming: list of fasta files (comma separated)',@stbb_db)
             #Adds 1 core for each database
             @params.get_param('vectors_db').split(/ |,/).each do |database|
                     cores << 1
                     ram << (@stbb_db.get_info(database,'index_size')/2.0**20).round(0) + base_ram 
             end
             ram.map!{ |iram| iram * @params.get_param('vectors_db').split(/ |,/).count }

             @params.check_param(errors,'vectors_kmer_size','Integer',31,'Main kmer size to use in vectors trimming')

             @params.check_param(errors,'vectors_min_external_kmer_size','Integer',11,'Minimal kmer size to use in read tips during vectors trimming')
    
             @params.check_param(errors,'vectors_max_mismatches','Integer',1,'Max number of mismatches accepted during vectors trimming')
   
             @params.check_param(errors,'vectors_minratio','String','0.80','Minimal ratio of vectors kmers in a read to be deleted')  
             
             @params.check_param(errors,'vectors_aditional_params','String',nil,'Aditional BBsplit parameters for vectors trimming, add them together between quotation marks and separated by one space')
    
             @params.check_param(errors,'vectors_trimming_aditional_params','String',nil,'Aditional BBsplit parameters for vectors trimming, add them together between quotation marks and separated by one space')

             @params.check_param(errors,'vectors_filtering_aditional_params','String',nil,'Aditional BBsplit parameters for vectors filtering, add them together between quotation marks and separated by one space')

             @params.check_param(errors,'vectors_merging_pairs_trimming','String','true','Trim vectors of paired reads using mergind reads methods for vectors trimming')
        #Set resources
             @params.resource('set_requirements',{ 'plugin' => 'PluginVectors','opts' => {'cores' => cores,'priority' => priority,'ram'=>ram}})
             return errors

       end
  #Get options
       def get_options

           #Opts Array
             opts = Array.new
           #TRIMING MODULE
           # Load aditional params
             @params.set_param('vectors_aditional_params',@params.get_param('vectors_trimming_aditional_params'))
           # Choosing which tips are going to be trimmed
             case @params.get_param('vectors_trimming_position')
                     when 'both'
                             ['r','l'].map { |tip| opts << get_trimming_module(tip,'vectors') }
                     when 'right'
                             opts << get_trimming_module('r','vectors')
                     when 'left'
                             opts << get_trimming_module('l','vectors')
             end 
           #FILTERING MODULE
           # Load aditional params
             @params.set_param('vectors_aditional_params',@params.get_param('vectors_filtering_aditional_params'))
           #Iteration to assemble individual options
             @params.get_param('vectors_db').split(/ |,/).each do |db|              
                #Add hash to array and return
                     opts << get_filtering_module(db,'vectors')
             end 
           #Return
             return opts

       end
 #Get cmd
       def get_cmd(result_hash)
           
               cmd = Array.new
           #Trimming
               result_hash['opts'].take(result_hash['opts'].count - @params.get_param('vectors_db').split(/ |,/).count).map { |opt| cmd << @bbtools.load_bbduk(opt) }
           #Filtering
               result_hash['opts'].drop(cmd.count).map { |opt| cmd << @bbtools.load_bbsplit(opt) }
           #Return  
               return cmd.join(' | ')

       end
 #Get trimming
       def get_trimming_module(ntip,plugin)

               h = super
               h['restrictleft'] = 58
               h['restrictright'] = 58
               return h

       end
 #Get stats
       def get_stats(stats_files,stats)

               stats["plugin_vectors"] = {} if !stats.key?('plugin_vectors')
               stats["plugin_vectors"]["sequences_with_vector"] = {} if !stats['plugin_vectors'].key?('sequences_with_vector')
               stats["plugin_vectors"]["sequences_with_vector"]["count"] = 0 if !stats['plugin_vectors']['sequences_with_vector'].key?('count')
               stats["plugin_vectors"]["vector_id"] = {} if !stats['plugin_vectors'].key?('vector_id')
            #Extracting trimming stats
               trimming_stats_files = stats_files['stats'].select { |file| (File.basename(file,'.txt') =~ /\S*trimming\S*/) }
               trimming_stats_files.each do |file|
                      lines = super('',file)
                      header_matched = lines.select { |line| (line =~ /^\s*#Matched/) }
                      ids = lines.select { |line| (line =~ /^(?!\s*#).+/) }
                      stats["plugin_vectors"]["sequences_with_vector"]["count"] += header_matched.first.split(/\t/)[1].to_i if !header_matched.empty?         
                      ids.map { |line| stats["plugin_vectors"]["vector_id"][line.split(/\t/)[0]] ||= 0 } 
                      ids.map { |line| stats["plugin_vectors"]["vector_id"][line.split(/\t/)[0]] += line.split(/\t/)[1].to_i } 
               end
            #Extracting filtering stats 
               filtering_file = stats_files['stats'].select { |file| (File.basename(file,'.txt') =~ /\S*filtering\S*/) }.first
               regexp_str = "^(?!\s*#).+"
               lines = super(regexp_str,filtering_file)
               lines.each do |line|
                             splitted_line = line.split(/\t/)
                             nreads = splitted_line[5].to_i + splitted_line[6].to_i
                             stats["plugin_vectors"]["vector_id"][splitted_line[0]] ||= 0
                             stats["plugin_vectors"]["vector_id"][splitted_line[0]] += nreads
                             stats["plugin_vectors"]["sequences_with_vector"]["count"] += nreads
               end

       end

end
