package one;

import java.io.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.Scanner;
import java.util.concurrent.CountDownLatch;

public class Task2 {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        System.out.println("=== Задание 2: Файл с числами, простые числа и факториалы ===\n");

        System.out.print("Введите путь к файлу для записи чисел: ");
        String sourceFile = scanner.nextLine();

        String primesFile = sourceFile + "_primes.txt";
        String factorialsFile = sourceFile + "_factorials.txt";

        int numbersCount = 10; // Количество чисел для записи
        CountDownLatch writeLatch = new CountDownLatch(1);
        CountDownLatch calcLatch = new CountDownLatch(2);

        // Статистика
        final int[] stats = {0, 0, 0}; // [всего чисел, простых чисел, факториалов]

        // Поток 1: Заполняет файл случайными числами
        Thread writerThread = new Thread(() -> {
            try (PrintWriter writer = new PrintWriter(new FileWriter(sourceFile))) {
                Random random = new Random();
                System.out.println("Поток записи: заполняю файл случайными числами...");

                for (int i = 0; i < numbersCount; i++) {
                    int num = random.nextInt(50) + 1; // 1-50
                    writer.println(num);
                }

                stats[0] = numbersCount;
                System.out.println("Поток записи: файл заполнен! Записано " + numbersCount + " чисел.");
                writeLatch.countDown();
            } catch (IOException e) {
                System.err.println("Ошибка записи в файл: " + e.getMessage());
            }
        });

        // Поток 2: Ищет простые числа
        Thread primesThread = new Thread(() -> {
            try {
                writeLatch.await();
                System.out.println("Поток простых чисел: начинаю поиск...");

                List<Integer> numbers = readNumbersFromFile(sourceFile);
                List<Integer> primes = new ArrayList<>();

                for (int num : numbers) {
                    if (isPrime(num)) {
                        primes.add(num);
                    }
                }

                // Записываем результат в файл
                try (PrintWriter writer = new PrintWriter(new FileWriter(primesFile))) {
                    writer.println("=== Простые числа ===");
                    for (int prime : primes) {
                        writer.println(prime);
                    }
                    writer.println("Всего простых чисел: " + primes.size());
                }

                stats[1] = primes.size();
                System.out.println("Поток простых чисел: найдено " + primes.size() + " простых чисел.");
                calcLatch.countDown();
            } catch (InterruptedException | IOException e) {
                Thread.currentThread().interrupt();
                System.err.println("Ошибка: " + e.getMessage());
            }
        });

        // Поток 3: Вычисляет факториалы
        Thread factorialThread = new Thread(() -> {
            try {
                writeLatch.await();
                System.out.println("Поток факториалов: начинаю вычисление...");

                List<Integer> numbers = readNumbersFromFile(sourceFile);

                // Записываем результат в файл
                try (PrintWriter writer = new PrintWriter(new FileWriter(factorialsFile))) {
                    writer.println("=== Факториалы чисел ===");

                    for (int num : numbers) {
                        long fact = factorial(num);
                        writer.printf("Факториал %d = %d%n", num, fact);
                    }

                    writer.println("Всего вычислено факториалов: " + numbers.size());
                }

                stats[2] = numbers.size();
                System.out.println("Поток факториалов: вычислено " + numbers.size() + " факториалов.");
                calcLatch.countDown();
            } catch (InterruptedException | IOException e) {
                Thread.currentThread().interrupt();
                System.err.println("Ошибка: " + e.getMessage());
            }
        });

        // Запускаем потоки
        long startTime = System.currentTimeMillis();

        writerThread.start();
        primesThread.start();
        factorialThread.start();

        try {
            calcLatch.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        long endTime = System.currentTimeMillis();

        // Выводим статистику в main
        System.out.println("\n=== СТАТИСТИКА В MAIN ===");
        System.out.println("Всего чисел в файле: " + stats[0]);
        System.out.println("Найдено простых чисел: " + stats[1]);
        System.out.println("Вычислено факториалов: " + stats[2]);
        System.out.println("Файл с простыми числами: " + primesFile);
        System.out.println("Файл с факториалами: " + factorialsFile);
        System.out.println("Время выполнения: " + (endTime - startTime) + " мс");
    }

    // Читает числа из файла
    private static List<Integer> readNumbersFromFile(String filePath) throws IOException {
        List<Integer> numbers = new ArrayList<>();
        try (BufferedReader reader = new BufferedReader(new FileReader(filePath))) {
            String line;
            while ((line = reader.readLine()) != null) {
                numbers.add(Integer.parseInt(line.trim()));
            }
        }
        return numbers;
    }

    // Проверка на простое число
    private static boolean isPrime(int n) {
        if (n <= 1) return false;
        if (n <= 3) return true;
        if (n % 2 == 0 || n % 3 == 0) return false;

        for (int i = 5; i * i <= n; i += 6) {
            if (n % i == 0 || n % (i + 2) == 0) {
                return false;
            }
        }
        return true;
    }

    // Вычисление факториала
    private static long factorial(int n) {
        if (n < 0) return -1;
        if (n == 0 || n == 1) return 1;

        long result = 1;
        for (int i = 2; i <= n; i++) {
            result *= i;
        }
        return result;
    }
}