module.exports.handler = async (event) => {
  console.log("Lambda invoked by Step Function:", event);

  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Hello from ASO!" })
  };
};