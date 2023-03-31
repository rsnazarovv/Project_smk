// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Импортируем стандартный контракт ERC20
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Определяем контракт стриминговой платформы
contract StreamingPlatform is Ownable {
    // Объявляем ERC20 токен
    ERC20 public token;

    // Объявляем список подписчиков
    address[] public subscribers;

    // Объявляем переменную для хранения времени первой раздачи токенов
    uint256 public startTime;

    // Объявляем переменную для хранения времени последней раздачи токенов
    uint256 public lastDistributionTime;

    // Объявляем переменную для хранения количества токенов, раздающихся каждую подписку
    uint256 public tokensPerSubscription;

    event Subscribed(address subscriber);
    event Unsubscribed(address subscriber);

    // Объявляем событие для логирования начала подписки
    event SubscriptionStarted(address indexed subscriber);

    // Объявляем событие для логирования изменения количества токенов, раздающихся каждую подписку
    event TokensPerSubscriptionChanged(uint256 newTokensPerSubscription);

    // Конструктор контракта
    constructor(
        address _tokenAddress,
        uint256 _tokensPerSubscription,
        uint256 _startTime
    ) {
        // Инициализируем ERC20 токен
        token = ERC20(_tokenAddress);

        // Инициализируем количество токенов, раздающихся каждую подписку
        tokensPerSubscription = _tokensPerSubscription;

        // Инициализируем время первой раздачи токенов
        startTime = _startTime;
    }

    // Функция для начала подписки
    function startSubscription() external {
        // Получаем адрес подписчика
        address subscriber = msg.sender;

        // Проверяем, что подписчик еще не был добавлен ранее
        require(!isSubscriber(subscriber), "Already subscribed");

        // Добавляем подписчика в список
        subscribers.push(subscriber);

        // Логируем начало подписки
        emit SubscriptionStarted(subscriber);
    }
    // Функция для подписки на стриминговую платформу
    function subscribe() external {
        // Проверяем, что отправитель не является подписчиком
        require(!isSubscriber(msg.sender), "Already subscribed");

        // Добавляем адрес отправителя в массив подписчиков
        subscribers.push(msg.sender);

        // Логируем подписку
        emit Subscribed(msg.sender);
    }

// Функция для отписки от стриминговой платформы
function unsubscribe() external {
    // Проверяем, что отправитель является подписчиком
    require(isSubscriber(msg.sender), "Not subscribed");

    // Ищем индекс адреса отправителя в массиве подписчиков
    uint256 index = 0;
    for (uint256 i = 0; i < subscribers.length; i++) {
        if (subscribers[i] == msg.sender) {
            index = i;
            break;
        }
    }

    // Удаляем адрес отправителя из массива подписчиков
    subscribers[index] = subscribers[subscribers.length - 1];
    subscribers.pop();

    // Логируем отписку
    emit Unsubscribed(msg.sender);
}

    // Функция для выпуска токенов подписчикам
    function distributeTokens() external {
        // Проверяем, что прошло достаточно времени с момента последней раздачи
        require(block.timestamp >= lastDistributionTime + 2 days, "Not enough time has passed");

        // Проверяем, что есть подписчики
        require(subscribers.length > 0, "No subscribers");

        // Вычисляем количество токенов для раздачи
        uint256 amount = tokensPerSubscription * subscribers.length;

        // Проверяем, что на балансе контракта достаточно токенов для раздачи
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");

        // Раздаем токены каждому подписчику
        for (uint256 i = 0; i < subscribers.length; i++) {
            address subscriber = subscribers[i];
            token.transfer(subscriber, tokensPerSubscription);
        }

        // Обновляем время последней раздачи
        lastDistributionTime = block.timestamp;
    }

    // Функция для изменения количества токенов, раздающихся каждую подписку
    function setTokensPerSubscription(uint256 _tokensPerSubscription) external onlyOwner {
        tokensPerSubscription = _tokensPerSubscription;

        // Логируем изменение количества токенов
        emit TokensPerSubscriptionChanged(tokensPerSubscription);
    }

    // Функция для проверки, является ли адрес подписчиком
    function isSubscriber(address _subscriber) public view returns (bool) {
        for (uint256 i = 0; i < subscribers.length; i++) {
            if (subscribers[i] == _subscriber) {
                return true;
            }
        }
        return false;
    }
    // Функция для получения количества подписчиков
    function getSubscriberCount() public view returns (uint256) {
        return subscribers.length;
    }
}