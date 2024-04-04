from subprocess import Popen
from pathlib import Path
import json
import time
import argparse
import yaml

parser = argparse.ArgumentParser()
parser.add_argument('--u', action='store', help='Docker username', type=str, required=True)
parser.add_argument('--p', action='store', help='Docker password', type=str, required=True)
args = parser.parse_args()

DIRECTORY_PATH = Path(__file__).resolve().parent

with open("./database.json") as json_file:
    db_data = json.load(json_file)

params = f' -var="db_password={db_data["password"]}" -var="db_username={db_data["user"]}"'

init_process = Popen(f'cd "{DIRECTORY_PATH}" && terraform init', shell=True)
init_process.wait()

apply_process = Popen(f'cd "{DIRECTORY_PATH}" && terraform apply' + params, shell=True)
apply_process.wait()

produce_output = Popen(f'cd "{DIRECTORY_PATH}" && terraform output -json > "{DIRECTORY_PATH}/output.json"', shell=True)

with open(f'{DIRECTORY_PATH}/output.json', "r") as file:
    data = json.loads(file.read())

# database_url = f"postgresql://{db_data['user']}:{db_data['password']}@{data['db_endpoint']['value'][0]}/to_do"
# with open("./database.txt", "w") as file:
#     file.write("DATABASE_URL=" + database_url)
#
# with open("./rust_config.yml") as file:
#     config = yaml.load(file, Loader=yaml.FullLoader)
#
# config["DB_URL"] = database_url
#
# with open("./rust_config.yml", "w") as file:
#     yaml.dump(config, file, default_flow_style=False)


server_ip = data["ec2_global_ips"]["value"][0][0]

print("waiting for server to be built")
time.sleep(5)
print("attempting to enter server")

build_process = Popen(f'cd "{DIRECTORY_PATH}" && sh ./run_build.sh {server_ip} {args.u} {args.p}', shell=True)
build_process.wait()


#  CURRENT ISSUE:  web app doesn't seem to properly take traffic when diesel is used => try deploy with embedded db first
