# parser file for fetching the content of the project_conf.config file


import re

import argparse 


# fetch the argumenst from the 


class config_gen:
    def __init__(self) -> None:
        # there are sections that contains items, 
        # now for every item there are values defined for them 
         
        self.sections = {}

        # every item is a single value only so we can say that the section 
        # contains a list of items that are of type dict and in that dict there 
        # is key value pair of items and their values
        self._section_item = {} 
        # but for sections that have list items, it is of type list 
        
        # in the cmake we will set every section item as var and their values 
        # would be items name  
        
        
    def parse_config(self,file_path):
        with open(file_path, 'r') as file:
            content = file.read()


        current_section = None
        current_item = None
        item_en_list = False
        
        in_list = False
        list_items = []

        # decode the lines in the scope below
        for line in content.splitlines():
            line = line.strip()
        
            # Skip comments
            if line.startswith('#') or not line:
                continue
            # print(line)
            # Handle sections handle 
            section_match = re.match(r'\[(.*)\]', line)
            if section_match:
                # update new dictionary item 
                current_section = section_match.group(1)
                self.sections.update({current_section : {}})
                # serarch for the section items 
                continue
            
            # check if we have a {} enclosed item, match the enclosed item 
            enclosed_list_item = re.match(r'\{(.*)\}', line)
            if enclosed_list_item:
                current_item = enclosed_list_item.group(1)
                item_en_list = True
                continue
                
            # Handle lists values 
            if line == '</start>':
                in_list = True
                list_items = []
                continue
            
            elif line == '</end>':
                if item_en_list:
                    self.sections[current_section].update({current_item: list_items})
                else :
                    self.sections[current_section] = list_items
                in_list = False
                item_en_list = False
                continue
            
            # Handle key-value pairs and variable substitutions
            if '=' in line and not in_list:
                key, value = map(str.strip, line.split('=', 1))
                if '$' in value:
                    value = re.sub( re.compile(r'\${(.*?)}'), lambda match: self.sections[current_section].get(match.group(1), ""), value)
                self.sections[current_section].update({key : value.strip('"')})
            elif in_list:
                for items in [x for x in line.split(" ")]:
                    list_items.append(items) if items else None



    def generate_cmake(self, output_path):
        conf_data  = self.sections
        # print(data)
        with open(output_path, 'w') as cmake_file:
            for section, data in conf_data.items():
                if isinstance(data, dict):
                    for key, value in data.items():
                        if isinstance(value, list):
                            cmake_file.write(f"set({key.upper()} \n")
                            cmake_file.write(f"\t")
                            for item in value:
                                cmake_file.write(f"{item}\t")
                            cmake_file.write(")\n")
                        
                        else : 
                            cmake_file.write(f'set({key.upper()} "{value}")\n')
                    # write section also 
                    cmake_file.write(f"set({section.upper()} \n")
                    cmake_file.write("\t")
                    for key,val in data.items():
                        cmake_file.write(f"{key.upper()}\t")
                    cmake_file.write(")\n")
                        
                
                elif isinstance(data, list):
                    cmake_file.write(f"set({section.upper()} \n")
                    cmake_file.write(f"\t")
                    for item in data:
                        cmake_file.write(f"{item}\t")
                    cmake_file.write(")\n")

    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process a configuration file and generate a CMake file.")
    parser.add_argument('config_path', help="Path to the configuration file")
    parser.add_argument('output_path', help="Path to the output CMake file")
    args = parser.parse_args()
    
    cfg_gen = config_gen()
    cfg_gen.parse_config(args.config_path)
    cfg_gen.generate_cmake(args.output_path)