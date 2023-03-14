import jwt
import json
import boto3

BEARER = "bearer"
ALLOW = "Allow"
DENY = "Deny"
EFFECTS = [ALLOW.lower(), DENY.lower()]

session = boto3.session.Session()

client = session.client(
    service_name="secretsmanager",
    region_name="ap-southeast-2",
)


def retrieve_auth_header_value(event_headers):
    print("retrieve_auth_header_value")
    """This function pulls out the auth info from the headers
    :param event_headers: the header from the event
    :return: the auth header or raises an Unauth exception
    """
    headers = {}
    try:
        print("EKeys", event_headers.keys())
        print(event_headers.values())
        if event_headers is None:
            raise Exception("Unauthorized")
        for key in event_headers:
            headers[key.lower()] = event_headers[key]
        print("HKeys", headers["authorization"])
        return headers["authorization"].split(" ")
    except Exception:
        raise Exception("Unauthorized")


def validate_auth_value(auth_split):
    """Validates the auth header values - make sure the structure is correct
    :param auth_split: an array container 'Bearer' and the jwt token
    :return: true if valid or raise Unauthorized error
    """
    print("validate_auth_value")
    if str(auth_split[0]).lower() == BEARER and len(auth_split) == 2:
        print("Split", auth_split)
        return True
    else:
        raise Exception("Unauthorized")


def get_token(auth_split):
    """Retrieve the the jwt token
    :param category: string category
    :return: true if valid or raise Unauthorized error
    """
    print("getToken")
    token = str(auth_split[1]).strip()
    print("Token", token)
    return token


def verify_short_token(client, token):
    """Verify the the short token against the jwt token
    :param client: boto3 client
    :param token: jwt token
    :return: the role (default merchant id)
    """
    print("getShortToken")
    response = client.get_secret_value(SecretId="data-api-gw-authoriser")
    secret_string = response["SecretString"]
    print("S", secret_string[0:2])
    secret_value = json.loads(secret_string)
    payload = jwt.decode(token, secret_value["jwt_shared_secret"], algorithms=["HS256"])
    print("P", payload)
    role = payload["role"]
    print("Role", role)
    return role


def lambda_handler(event, context):
    print(event)
    print(json.dumps(event))
    try:
        auth_value = retrieve_auth_header_value(event["headers"])
        print("AuthH", auth_value)
        if validate_auth_value(auth_value):
            token = get_token(auth_value)
            role = verify_short_token(client, token)
            print("Success")
            return {"isAuthorized": not (not role), "context": {}}

    except Exception as e:
        print(e)
        print("Fail")
        pass
    print("Unsuccessful")
    return {"isAuthorized": False, "context": {}}
