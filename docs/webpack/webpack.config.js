const path = require('path');
const FontminPlugin = require('fontmin-webpack')
const MiniCssExtractPlugin = require("mini-css-extract-plugin");

module.exports = {
    entry: './src/main.js',
    output: {
        path: path.resolve(__dirname, 'dist'),
        filename: 'main.js'
    },
    module: {
        // TODO(pyoung): https://webpack.js.org/guides/production/
        rules: [
            {
                test: /\.(sa|sc|c)ss$/i,
                use: [
                    // Creates `style` nodes from JS strings
                    // "style-loader",
                    MiniCssExtractPlugin.loader,
                    // Translates CSS into CommonJS
                    "css-loader",
                    // Compiles Sass to CSS
                    "sass-loader",
                ]
            },
            {
                test: /\.(ttf|otf|eot|svg|woff(2)?)(\?v=\d+\.\d+\.\d+)?$/,
                loader: 'file-loader',
                // include: [path.resolve(__dirname, "../node_modules/@fortawsome/fontawesome-free/webfonts/")],
                options: {
                    name: '[name].[ext]?[hash]',
                    outputPath: 'fonts/'
                }
            }, // {
            //     test: /\.svg$/,
            //     loader: 'svg-url-loader',
            //     include: [path.resolve(__dirname, "../node_modules/flag-icon-css/flags/1x1/")],
            //     options: {
            //         name: '[name].[ext]?[hash]',
            //         outputPath: 'flags/'
            //     }
            // }
        ]
    },
    plugins: [
        new MiniCssExtractPlugin(),
        new FontminPlugin({
            autodetect: true, // automatically pull unicode characters from CSS
            glyphs: ['\uf0c8' /* extra glyphs to include */],
        }),
    ]
};
