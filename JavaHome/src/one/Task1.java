package one;

import java.util.Random;
import java.util.concurrent.CountDownLatch;

public class Task1 {
    private static int[] array;
    private static long sum;
    private static double average;

    // Защёлка для синхронизации: 1 поток заполняет, 2 ждут
    private static final CountDownLatch fillLatch = new CountDownLatch(1);
    // Защёлка для ожидания завершения вычислений
    private static final CountDownLatch calcLatch = new CountDownLatch(2);

    public static void main(String[] args) throws InterruptedException {
        int size = 10;
        array = new int[size];

        System.out.println("=== Задание 1: Массив, сумма и среднее ===\n");

        // Поток 1: Заполняет массив случайными числами
        Thread fillerThread = new Thread(() -> {
            Random random = new Random();
            System.out.println("Поток заполнения: начинаю заполнять массив...");

            for (int i = 0; i < array.length; i++) {
                array[i] = random.nextInt(100) + 1; // 1-100
            }

            System.out.println("Поток заполнения: массив заполнен!");
            fillLatch.countDown(); // Сигнализируем, что массив готов
        });

        // Поток 2: Вычисляет сумму
        Thread sumThread = new Thread(() -> {
            try {
                fillLatch.await(); // Ждём заполнения массива
                System.out.println("Поток суммы: начинаю вычисление...");

                sum = 0;
                for (int num : array) {
                    sum += num;
                }

                System.out.println("Поток суммы: вычисление завершено! Сумма = " + sum);
                calcLatch.countDown();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });

        // Поток 3: Вычисляет среднее арифметическое
        Thread avgThread = new Thread(() -> {
            try {
                fillLatch.await(); // Ждём заполнения массива
                System.out.println("Поток среднего: начинаю вычисление...");

                long tempSum = 0;
                for (int num : array) {
                    tempSum += num;
                }
                average = (double) tempSum / array.length;

                System.out.println("Поток среднего: вычисление завершено! Среднее = " + average);
                calcLatch.countDown();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });

        // Запускаем все потоки
        fillerThread.start();
        sumThread.start();
        avgThread.start();

        // Ждём завершения всех вычислений
        calcLatch.await();

        // Выводим результаты в main
        System.out.println("\n=== РЕЗУЛЬТАТЫ В MAIN ===");
        System.out.print("Массив: ");
        for (int num : array) {
            System.out.print(num + " ");
        }
        System.out.println("\nСумма элементов: " + sum);
        System.out.println("Среднее арифметическое: " + average);
    }
}