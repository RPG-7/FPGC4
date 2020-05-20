# Documentation
- to work on the documentation:
	- execute ./run.sh to host a local version on localhost:6969
	- when a file is changed, the website should refresh automatically
- to deploy the website on the server:
	- execute ./deploy.sh
	- this will:
		- build the site to the ./site directory
		- remove the old fpgc4 folder on the server
		- copy the site directory to the server, with fpgc4 as name
		- recursively set group to www-data
	- just make sure you use public key authentication to the server, so no password prompts come up during the script





## Notes for markdown documentation

!!! note ""
    Note example


!!! info
	yeet

!!! tip
    hot

!!! success
    Lorem

!!! question
    whomst'd've?

!!! fail
    f

!!! danger
    risk

!!! bug
    to fix

!!! example
    ```
    code
    ```
