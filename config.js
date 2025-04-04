
const networkConfig = {
    31337: {
        name: "localhost"
    },
    1337: {
        name: "ganache"
    },
    11155111: {
        name: "sepolia",
        ethUsdPriceFeed: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
        blockConfirmations: 6,
    },
    // Price Feed Address, values can be obtained at https://docs.chain.link/data-feeds/price-feeds/addresses
    // Default one is ETH/USD contract on Sepolia
};

const developmentChains = ["hardhat", "localhost", "ganache"];
module.exports = {
    networkConfig,
    developmentChains,
}