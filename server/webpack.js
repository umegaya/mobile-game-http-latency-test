const path = require('path');
const nodeExternals = require('webpack-node-externals');
const packageInfo = require(path.join(__dirname, 'package.json'));

module.exports = {
    mode: process.env.CONFIG_NAME === "prod" ? 'production' : 'development',
    optimization: {
        minimize: false,
    },
    module: {
        rules: [
            { test: /\.ts$/, use: 'ts-loader' }
        ]
    },
    resolve: {
        // Add `.ts` and `.tsx` as a resolvable extension.
        extensions: [".ts", ".js"],
    },
    externals: [nodeExternals({
        whitelist: [/.*/]
    })],
    entry: path.resolve(__dirname, 'main.ts'),
    devtool: false,
    target: 'node',
    output: {
        filename: 'index.js',
        path: path.resolve(path.join(__dirname, 'build')),
        libraryTarget: 'commonjs',
    },
};
