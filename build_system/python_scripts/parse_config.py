# parser file for fetching the content of the project_conf.config file


import re

import argparse 


# fetch the argumenst from the 


class config_gen:
    def __init__(self) -> None:
        # there are sections that contains items, 
        # now for every item there are values defined for them 
         
        self.sections = []

        # every item is a single value only so we can say that the section 
        # contains a list of items that are of type dict and in that dict there 
        # is key value pair of items and their values
        self._section_item = {} 
        # but for sections that have list items, it is of type list 
        
        
    def parse_config(self,file_path):
        with open(file_path, 'r') as file:
            content = file.read()

        config_data = {}
        current_section = None
        in_list = False
        list_items = []

        # decode the lines in the scope below
        for line in content.splitlines():
            line = line.strip()

            # get every line and decode it 
            
            # Skip comments
            if line.startswith('#') or not line:
                continue

            # Handle sections handle 
            section_match = re.match(r'\[(.*)\]', line)
            if section_match:
                if current_section and in_list:
                    config_data[current_section] = list_items
                    in_list = False
                    list_items = []
                current_section = section_match.group(1).lower()
                config_data[current_section] = {}
                continue

            # Handle lists
            if line == '</start>':
                in_list = True
                list_items = []
                continue
            elif line == '</end>':
                config_data[current_section] = list_items
                in_list = False
                continue

            # Handle key-value pairs and variable substitutions
            if '=' in line and not in_list:
                key, value = map(str.strip, line.split('=', 1))
                if '@' in value:
                    value = re.sub(r'@(\w+)', lambda match: config_data.get(match.group(1).lower(), ""), value)
                config_data[current_section][key.lower()] = value.strip('"')
            elif in_list:
                list_items.append(line)

        return config_data

    def generate_cmake(self,config_data : dict, output_path):
        with open(output_path, 'w') as cmake_file:
            for section, data in config_data.items():
                if isinstance(data, dict):
                    for key, value in data.items():
                        cmake_file.write(f'set({key.upper()} "{value}")\n')
                elif isinstance(data, list):
                    cmake_file.write(f"set({section.upper()} \n")
                    for item in data:
                        cmake_file.write(f"    {item}\n")
                    cmake_file.write(")\n")
    
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process a configuration file and generate a CMake file.")
    parser.add_argument('config_path', help="Path to the configuration file")
    parser.add_argument('output_path', help="Path to the output CMake file")
    args = parser.parse_args()
    
    cfg_gen = config_gen()
    data =cfg_gen.parse_config(args.config_path)
    cfg_gen.generate_cmake(data,args.output_path)