import requests
import random

gitee_url = "https://gitee.com/"
base_url = "https://gitee.com/src-openeuler/mariadb/issues/"

proxy_list = [
    "http://8080",
    "http://8080",
    "http://8080",
    "http://8080",
    "http://8080",
    "http://8080",
    "http://8080",
    "http://8080"
]

proxies = {
    # "http": random.choice(proxy_list),
    # "https": random.choice(proxy_list)
    "http": "http://8080/",
    "https": "http://8080/"
}
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 '
                  'Safari/537.36 '
}

session = requests.session()
response = session.get(base_url, headers=headers, proxies=proxies, verify=False)

from lxml import etree
import json

ISSUE_WRAPPER = '//div[@class="issue-title"]'

html = etree.HTML(response.text)
CVE_ISSUE_TITLE = '//a[@class="title" and starts-with(@title, "CVE")]'
REPORTER = '//div[@class="issue-desc other-info-row d-align-center"]'  # data-username
ASSIGNEE = '//a[@class="author_link avatar d-flex-center js-popover-card"]'  # data-username
results = html.xpath(ISSUE_WRAPPER)

STATUS = '//div[@class="ui label d-inline-flex d-align-center issue-label-item" and starts-with(@data-name, "CVE")]'
SIG_GROUP = '//div[@class="ui label d-inline-flex d-align-center issue-label-item" and starts-with(@data-name, "sig")]'

cve_status = {}
sig_group = dict(html.xpath(SIG_GROUP)[0].attrib).get('data-name')

# test
first_cve = None

for cve_name_url_element, status_element in zip(html.xpath(CVE_ISSUE_TITLE), html.xpath(STATUS)):
    cve_name_url_element = dict(cve_name_url_element.attrib)
    status_element = dict(status_element.attrib)

    cve_name = cve_name_url_element.get('title')
    href = cve_name_url_element.get('href')
    status = status_element.get('data-name')

    cve_status[cve_name] = {'url': gitee_url + href,
                            'status': status,
                            'sig': sig_group}
    if not first_cve:
        first_cve = cve_name

first_url = cve_status.get(first_cve).get('url')


response_cve = session.get(first_url, headers=headers, proxies=proxies, verify=False)

html_cve = etree.HTML(response_cve.text)
result_cve = html_cve.xpath('//div[@class="git-issue-description markdown-body"]')
REPORTER = '//div[@class="git-issue-description markdown-body"]'  # username
ASSIGNEE = '//div[@class="selected-users"]/following::div[@class="username"]/text()'
DESC_CONTENT = '//div[@class="git-issue-description markdown-body"]//text()'
reporter = dict(html_cve.xpath(REPORTER)[0].attrib).get('username')
assignees = html_cve.xpath(ASSIGNEE)

cve_status[first_cve]['reporter'] = reporter
cve_status[first_cve]['assignees'] = assignees

texts = html_cve.xpath(DESC_CONTENT)

n = 0
affected_app = None
affected_version = None
score = None
priority = None
english_desc = None
publish_time = None
issue_create_time = None
search_url = None
template = None
while n < len(texts):
    line = texts[n]
    if "漏洞归属组件" in line:
        affected_app = texts[n + 1]
        n += 1
    elif "漏洞归属的版本" in line:
        affected_version = line.split("：")[1].strip()
    elif "BaseScore" in line:
        score = line.split("：")[1].strip().split(" ")[0].strip()
        priority = line.split("：")[1].strip().split(" ")[1].strip()
    elif "漏洞简述" in line:
        english_desc = texts[n + 1][1:]
        n += 1
    elif "漏洞公开时间" in line:
        publish_time = line.split("：")[1].strip()
        import datetime
        publish_time = datetime.datetime.fromisoformat(publish_time)
    elif "漏洞创建时间" in line:
        issue_create_time = line.split("：")[1].strip()
        import datetime
        issue_create_time = datetime.datetime.fromisoformat(issue_create_time)
    elif "漏洞详情参考链接" in line:
        cur_line = n + 1
        while "https" not in texts[cur_line]:
            cur_line += 1

        search_url = texts[cur_line]
        n = cur_line
    elif "漏洞分析结构反馈" in line:
        template = texts[n+1:]
        break
    n += 1

### TODO translation implementation
###

# Search url analysis
response_search = session.get(search_url, headers=headers, proxies=proxies, verify=False)

html_cve = etree.HTML(response_search.text)

'//a[@class="title" and starts-with(@title, "CVE")]'
REF_LINK_TYPES = '//td[starts-with(@data-testid, "vuln-hyperlinks-")]//text()'
parse_ref_res = html_cve.xpath('//td[starts-with(@data-testid, "vuln-hyperlinks-")]//text()')

leng = len(parse_ref_res)
n = 0
types = []
link = None
ref_link_types = {}
while n < leng:
    if "http" in parse_ref_res[n]:
        key = parse_ref_res[n]
        types = []

        # get following types
        cur_n = n + 1
        while cur_n < leng:
            if "\t" in parse_ref_res[cur_n] or "\r" in parse_ref_res[cur_n]:
                cur_n += 1
                continue
            elif "http" in parse_ref_res[cur_n]:
                n = cur_n
                break
            else:
                types.append(parse_ref_res[cur_n])
                cur_n += 1
        n = cur_n
        ref_link_types[key] = types
    else:
        n += 1

## check the upstream link, not check the other 3rd part link from types verification
target_ref = []

for link in ref_link_types.keys():
    if "Third Party Advisory" in ref_link_types[link]:
        continue
    if 'Issue Tracking' in ref_link_types[link] or 'Vendor Advisory' in ref_link_types[link]:
        target_ref.append(link)

github_baseurl = "https://github.com/"

# TODO need store into a object and get the specific github repo name
target_repo_name = "MariaDB/server"

# TODO consider how to define/collect the query info
# Such as, Mariadb should be a JIRA/github commits link
query_what = "MDEV-24040"
github_target_search_base_url = github_baseurl + target_repo_name + "/search?q=" + query_what + "&type="

# https://github.com/MariaDB/server/search?q=MDEV&type=issues
search_types = ["code", "commits", "issues"]
result_links = {}
for search_type in search_types:
    github_target_search_url = github_target_search_base_url + search_type

    github_resp = session.get(github_target_search_url, headers=headers, proxies=proxies, verify=False)

    html_one = etree.HTML(github_resp.text)

    ress = html_one.xpath("//a/@data-hydro-click")
    result_links_for_1_type = []
    get_first_3 = 0
    for res_1 in ress:
        if "payload" in json.loads(res_1) and get_first_3 < 3:
            payload = json.loads(res_1)['payload']
            if "result" in payload and "url" in payload['result']:
                result_links_for_1_type.append(payload["result"]["url"])
                get_first_3 += 1
    result_links[search_type] = result_links_for_1_type[:]

# if in code/commits, should check the said code commit merged to which branches/tags
# if in issues, should check the associated code commit merged to which branches/tags

# For a single issue PR link example
DEMO_PR_LINK = 'https://github.com/MariaDB/server/pull/1688'
pr_defix = DEMO_PR_LINK.split(target_repo_name)[1]

pr_resp = session.get(DEMO_PR_LINK, headers=headers, proxies=proxies, verify=False)
COMMIT_LINK_PARSE = '//code/following::a[starts-with(@href, "%s")]/@href'
specific_commit_link_parse = COMMIT_LINK_PARSE % ("/" + target_repo_name + pr_defix)
html_pr = etree.HTML(pr_resp.text)
commit_ress = html_pr.xpath(specific_commit_link_parse)

commit_search = []

for commit_res in commit_ress:
    commit_search.append(github_baseurl + str(commit_res))


# a single commit_url search for collecting the all merged taged to collect the upstream versions.
SAMPLE_COMMIT_URL = "https://github.com//MariaDB/server/pull/1688/commits/3829b408d689182f05804ec045c9705da8de4e34"

from selenium import webdriver
chrome_options = webdriver.ChromeOptions()
chrome_options.add_argument("--proxy-server={0}".format(proxies["http"]))
chrome_options.add_argument('--headless')
# , chrome_options=chrome_options
chrome_driver = webdriver.Chrome(executable_path="C:\\Program Files\\Google\\Chrome\\Application\\chromedriver.exe")
from selenium.webdriver.support.wait import WebDriverWait
chrome_driver.set_window_size(1, 1)

chrome_driver.get(SAMPLE_COMMIT_URL)
# TODO find another good way to wait the dynamic elements are loaded
import time
time.sleep(2)


safe_html = etree.HTML(chrome_driver.page_source)

# TODO need to clean the browser
chrome_driver.close()

TAG_LIST_PARSE = '//ul[@class="branches-tag-list js-details-container"]/li/a/text()'
tag_ress = safe_html.xpath(TAG_LIST_PARSE)

commit_tags = []

for tag_res in tag_ress:
    commit_tags.append(str(tag_res))

# TODO need to compare the said tags with the existing versions in openEuler
# and verify the existing versions are affected

import requests
GITEE_API = "https://gitee.com/api/v5/"
REPO_NAME = "mariadb"
headers = {'Content-Type': "application/json", "charset": "UTF-8" }

branches_resp = requests.get(GITEE_API + "repos" + "/" + "src-openeuler" + "/" + REPO_NAME + "/" + "branches", proxies=proxies, headers=headers, verify=False)


import json
branch_ress = json.loads(branches_resp.content)
import collections
official_branches = collections.defaultdict(dict)

"https://gitee.com/src-openeuler/mariadb/tree/openEuler-22.03-LTS/"
"https://gitee.com/src-openeuler/mariadb/raw/openEuler-22.03-LTS/mariadb.spec"
cur_branches_version = {}
for branch in branch_ress:
    if branch['protected']:
        branch_name = branch["name"]
        splited_trees = branch_name.split("-")
        global_trees = official_branches
        # Construct the tree model
        for tree_elem in splited_trees:
            if tree_elem not in global_trees:
                global_trees[tree_elem] = dict()
            global_trees = global_trees[tree_elem]

        # get the app version of specific branch from spec file
        TEST_URL = "https://gitee.com/src-openeuler/mariadb/raw/%s/mariadb.spec" % branch_name
        spec_resp = requests.get(TEST_URL, proxies=proxies, headers=headers, verify=False)
        import re
        res = re.findall("Version:\s+(.-\w)+", spec_resp.text)
        app_version = re.findall("Version:\s+(\d+\.(?:\d+\.)*\d+)", spec_resp.text)[0]
        pkg_release_version = re.findall("Release:\s+(\d+)", spec_resp.text)[0]
        cur_branches_version[branch_name] = {'version': app_version, 'release': pkg_release_version}

        # Get the tag_prefix and seperator for processing the following comparision
        TEST_YAML_URL = "https://gitee.com/src-openeuler/mariadb/raw/%s/mariadb.yaml" % branch_name
        repo_yaml_resp = requests.get(TEST_YAML_URL, proxies=proxies, headers=headers, verify=False)
        import re
        try:
            tag_prefix = re.findall("tag_prefix: \"(.+)\"", repo_yaml_resp.text)[0]
        except:
            tag_prefix = None
        try:
            seperator = re.findall("seperator: \"(.+)\"", repo_yaml_resp.text)[0]
        except:
            seperator = None
        cur_branches_version[branch_name]['tag_prefix'] = tag_prefix
        cur_branches_version[branch_name]['seperator'] = seperator
# analysis the cve affective decription and compare with the collected merged upstream branches
# to check whether the said branches in CVE are affected

commit_tags = []

# analysis the template which need to insert values
template = "".join(template)
lines = template.split("\n")
n = 0
leng = len(lines)

while n < leng:
    line = lines[n]
    if line.startswith('影响性分析说明'):
        lines[n+1] = english_desc
        n += 2
        continue
    elif line.startswith("受影响版本排查"):
        # Get the answer which will insert into the final result of CVE comment.
        ans_yes, ans_no = line.split("(")[1][:-2].split("/")

        next_n = n + 1
        while next_n < leng:
            new_line = lines[next_n]
            if new_line.startswith("修复是否涉及abi变化"):
                n = next_n - 1
                break
            elif new_line:

                import re
                cve_branch = re.match("\d+\\.(((openEuler-\d+\.\d+)|(master))?(-\w+)*)", new_line).group(1)

                cve_app_version = re.findall("\((\d+\.(?:\d+\.)*\d+)\)", new_line)[0]

                tag_prefix = cur_branches_version[cve_branch]['tag_prefix']
                seperator = cur_branches_version[cve_branch]['seperator']
                tags = [x.split(tag_prefix)[1] for x in commit_tags]
                if cve_app_version not in tags:
                    lines[next_n] += " " + ans_yes
                else:
                    lines[next_n] += " " + ans_no

            next_n += 1
        continue

    elif line.startswith("修复是否涉及abi变化"):
        # Get the answer which will insert into the final result of CVE comment.
        ans_abi_yes, ans_abi_no = line.split("(")[1][:-2].split("/")

        next_n = n + 1
        while next_n < leng:
            new_line = lines[next_n]
            if new_line.startswith("修复是否涉及abi变化"):
                n = next_n - 1
                break
            elif new_line:
                # consider how to evaluate the
                lines[next_n] += " " + ans_abi_no

            next_n += 1
        break
    n += 1

print("\n".join(lines))

