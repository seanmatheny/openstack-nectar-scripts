#!/usr/bin/env python3
#older script, predating the allocations openstack module tool. See bash version.
#script to notify of nectar openstack allocation requests waiting to be approved
#may want to add a date comparison on submit_date to only notify for a couple days (or enough to capture weekend)
from nectar_tools import allocations
from nectar_tools import config
from nectar_tools.allocations import states
import json
#for running openstack command
import subprocess
#for email
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
#for creds
from rcadmin import *

dest_email = "nectaralerts@uoa.auckland.ac.nz"
from_email = "s.matheny@auckland.ac.nz"

def sendemail(submit_date, project_name, approver_email, project_description, end_date, dest_email, from_email):
  # Create message container - the correct MIME type is multipart/alternative.
  msg = MIMEMultipart('alternative')
  msg['Subject'] = "Pending Nectar Project Allocation Reqeust:"
  msg['From'] = from_email
  msg['To'] = dest_email

  # Create the body of the message (a plain-text and an HTML version).
  text = "New Pending Nectar Allocation\nThis email has HTML-only details becuase Sean is lazy.\n"
  html = """\
  <html>
    <head></head>
    <body>
      <p>New Pending Nectar Request:<br>
         <br>
         <b>Submitted:</b> """ +str(submit_date)+ """<br>
         <b>Project Name</b> """ +str(project_name)+ """<br>
         <b>Approver Email:</b> """ +str(approver_email)+ """<br>
         <b>Project Description</b> """ +str(project_description)+ """<br>
         <b>Project End:</b> """ +str(end_date)+ """<br>
         <br>Login to the <a href="https://dashboard.rc.nectar.org.au">Nectar Dashboard</a> to review.
      </p>
    </body>
  </html>
  """

  # Record the MIME types of both parts - text/plain and text/html.
  part1 = MIMEText(text, 'plain')
  part2 = MIMEText(html, 'html')

  # Attach parts into message container.
  # According to RFC 2046, the last part of a multipart message, in this case
  # the HTML message, is best and preferred.
  msg.attach(part1)
  msg.attach(part2)

  # Send the message via local SMTP server.
  s = smtplib.SMTP('localhost')
  # sendmail function takes 3 arguments: sender's address, recipient's address
  # and message to send - here it is sent as one string.
  s.sendmail(from_email, dest_email, msg.as_string())

#end ofemail function, begin work to get allocations info

CONF = config.CONFIG
CONF.read("/root/nectar/allocations/nectar-tools.conf")

manager = allocations.AllocationManager(
                CONF.allocations.api_url,
                CONF.allocations.username,
                CONF.allocations.password)

#build dict from openstack subprocess query
#projectid=subprocess.getoutput("/usr/bin/openstack --os-project-name admin --os-username auckland-admin --os-password {0} --os-auth-url https://keystone.rc.nectar.org.au:5000/v3/ --os-user-domain-name default --os-project-domain-name default --os-identity-api-version 3 project list --domain nz --format value| grep -v pt- | cut -d ' ' -f1".format(auckland_pw))
projectid=subprocess.getoutput("/usr/bin/openstack --os-project-name admin --os-username auckland-admin --os-password {0} --os-auth-url https://keystone.rc.nectar.org.au:5000/v3/ --os-user-domain-name default --os-project-domain-name default --os-identity-api-version 3 project list --domain nz --format value| grep -v pt- | cut -d ' ' -f1".format(auckland_pw))

#loop through all current NZ projects
for id in projectid.split('\n')[:10]:
  try:
    allocation = manager.get_current_allocation(project_id=id)
    #filter for unapproved projects only, then get values we need from alloc dict
    if allocation.status == 'X':
       ae = allocation.__dict__['approver_email']
       pn = allocation.__dict__['project_name']
       pd = allocation.__dict__['project_description']
       ed = allocation.__dict__['end_date']
       sd = allocation.__dict__['submit_date']
       #send an email with these values
       sendemail(sd, pn, ae, pd, ed, dest_email, from_email)
  except Exception as e:
       print(e)
