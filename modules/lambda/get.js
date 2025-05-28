exports.handler = async (event) => {
  // For AWS_PROXY integration, query params are in event.queryStringParameters
  const value = event.queryStringParameters && event.queryStringParameters.value
    ? event.queryStringParameters.value
    : null;

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: "Lambda executed successfully ASO",
      value: value
    })
  };
};
