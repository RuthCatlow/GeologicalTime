var ExtractTextPlugin = require("extract-text-webpack-plugin");

module.exports = {
	entry: "./src/index.js",
	output: {
		path: __dirname,
		filename: "dist/bundle.js"
	},
	module: {
		loaders: [
			{ test: /\.css$/, loader: ExtractTextPlugin.extract("style-loader", "css-loader") },
			// { test: /\.css$/, loader: "style!css" },
      { test: /\.woff$|.eot$|.svg$|.ttf$|.png$|.gif$|.jpg$|.jpeg$/, loader: "url" },
		]
	},
	plugins: [
		new ExtractTextPlugin("dist/styles.css")
	]
};
