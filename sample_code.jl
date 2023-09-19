using AWS

aws_access_key_id = get(ENV,"AWS_ACCESS_KEY_ID","")
aws_secret_access_key = get(ENV, "AWS_SECRET_ACCESS_KEY","")
aws_region = get(ENV,"AWS_DEFAULT_REGION","us-east-1")

const AWS_GLOBAL_CONFIG = Ref{AWS.AWSConfig}()
creds = AWSCredentials(aws_access_key_id, aws_secret_access_key)
# Retrieve the global AWS configuration. If one is not set, create one with default configuration options.
AWS_GLOBAL_CONFIG[] = AWS.global_aws_config(region=aws_region, creds=creds)

@service S3

prefix = ""
delimitter = ""
max_keys = 1000 # Inf to retrieves all keys
continuation_token = ""

data = S3.list_objects("ezygotestbucket"; aws_config=AWS_GLOBAL_CONFIG[])

data = S3.create_bucket("ezygotestbucketnew",
    Dict(
        "CreateBucketConfiguration" => Dict(
            "LocationConstraint" => aws_region,
            "x-amz-acl" => "private"
        )
    );
    aws_config=AWS_GLOBAL_CONFIG[]
)

AWS.sign_aws4!(AWS_GLOBAL_CONFIG[], s3, now())
data = S3.list_buckets(
    aws_config=AWS_GLOBAL_CONFIG[]
)

acl = "private"
metadata = Dict("example" => "metadata")
tags = Dict("example" => "tag")
data_string_to_put = """{key: value}"""

meta = Dict("x-amz-meta-$k" => v for (k, v) in metadata)
head = merge!(
    Dict(
        "x-amz-acl" => acl,
        "x-amz-tagging" => URIs.escapeuri(tags),
        "Content-Encoding" => "",
        "Content-Type" => "",
    ),
    meta
)
image_data = read("image.png")
S3.put_object(
    "ezygotestbucket", "/image.png", 
    Dict(
        "body" => image_data,
        "headers" => head
    );
    aws_config=AWS_GLOBAL_CONFIG[]
);
