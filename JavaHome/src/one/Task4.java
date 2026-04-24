package one;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.regex.Pattern;

public class Task4 {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        System.out.println("=== Задание 4: Поиск слова и удаление запрещённых слов ===\n");

        System.out.print("Введите путь к директории для поиска: ");
        String searchDir = scanner.nextLine();

        System.out.print("Введите слово для поиска: ");
        String searchWord = scanner.nextLine();

        String forbiddenWordsFile = "forbidden_words.txt"; // Файл с запрещёнными словами
        String mergedFile = "merged_result.txt";
        String finalFile = "final_result.txt";

        // Статистика
        AtomicInteger filesFound = new AtomicInteger(0);
        AtomicInteger forbiddenWordsRemoved = new AtomicInteger(0);
        AtomicInteger totalReplacements = new AtomicInteger(0);

        CountDownLatch searchLatch = new CountDownLatch(1);
        CountDownLatch cleanLatch = new CountDownLatch(1);

        // Поток 1: Ищет файлы со словом и объединяет их содержимое
        Thread searchThread = new Thread(() -> {
            try {
                System.out.println("Поток поиска: ищу файлы со словом '" + searchWord + "'...");

                Path dir = Paths.get(searchDir);
                StringBuilder mergedContent = new StringBuilder();
                List<Path> foundFiles = new ArrayList<>();

                if (Files.exists(dir) && Files.isDirectory(dir)) {
                    try (DirectoryStream<Path> stream = Files.newDirectoryStream(dir, "*.txt")) {
                        for (Path file : stream) {
                            if (Files.isRegularFile(file)) {
                                String content = Files.readString(file);
                                if (content.toLowerCase().contains(searchWord.toLowerCase())) {
                                    foundFiles.add(file);
                                    filesFound.incrementAndGet();
                                    mergedContent.append("=== Файл: ").append(file.getFileName()).append(" ===\n");
                                    mergedContent.append(content).append("\n\n");
                                    System.out.println("Найден файл: " + file.getFileName());
                                }
                            }
                        }
                    }
                }

                // Записываем объединённый результат
                try (PrintWriter writer = new PrintWriter(new FileWriter(mergedFile))) {
                    writer.println("=== Результаты поиска слова '" + searchWord + "' ===");
                    writer.println("Найдено файлов: " + foundFiles.size());
                    writer.println();
                    writer.println(mergedContent.toString());
                }

                System.out.println("Поток поиска: объединение завершено! Файлов найдено: " + foundFiles.size());
                searchLatch.countDown();

            } catch (IOException e) {
                System.err.println("Ошибка поиска: " + e.getMessage());
                searchLatch.countDown();
            }
        });

        // Поток 2: Ждёт завершения первого и удаляет запрещённые слова
        Thread cleanThread = new Thread(() -> {
            try {
                searchLatch.await(); // Ждём завершения поиска
                System.out.println("Поток очистки: начинаю удаление запрещённых слов...");

                // Читаем запрещённые слова
                Set<String> forbiddenWords = new HashSet<>();
                try {
                    List<String> lines = Files.readAllLines(Paths.get(forbiddenWordsFile));
                    for (String line : lines) {
                        String word = line.trim().toLowerCase();
                        if (!word.isEmpty()) {
                            forbiddenWords.add(word);
                        }
                    }
                    System.out.println("Загружено запрещённых слов: " + forbiddenWords.size());
                } catch (IOException e) {
                    System.out.println("Файл с запрещёнными словами не найден, используется пустой список.");
                }

                // Читаем объединённый файл
                String content = Files.readString(Paths.get(mergedFile));
                String originalContent = content;

                // Удаляем запрещённые слова
                for (String word : forbiddenWords) {
                    String regex = "(?i)\\b" + Pattern.quote(word) + "\\b";
                    java.util.regex.Pattern pattern = java.util.regex.Pattern.compile(regex);
                    java.util.regex.Matcher matcher = pattern.matcher(content);

                    int count = 0;
                    StringBuffer sb = new StringBuffer();
                    while (matcher.find()) {
                        count++;
                        matcher.appendReplacement(sb, "***");
                    }
                    matcher.appendTail(sb);
                    content = sb.toString();

                    if (count > 0) {
                        forbiddenWordsRemoved.incrementAndGet();
                        totalReplacements.addAndGet(count);
                        System.out.println("Удалено слово '" + word + "' (" + count + " раз)");
                    }
                }

                // Записываем очищенный результат
                try (PrintWriter writer = new PrintWriter(new FileWriter(finalFile))) {
                    writer.println("=== Очищенный результат ===");
                    writer.println("Запрещённых слов удалено: " + forbiddenWordsRemoved.get());
                    writer.println("Всего замен: " + totalReplacements.get());
                    writer.println();
                    writer.println(content);
                }

                System.out.println("Поток очистки: очистка завершена!");
                cleanLatch.countDown();

            } catch (InterruptedException | IOException e) {
                Thread.currentThread().interrupt();
                System.err.println("Ошибка очистки: " + e.getMessage());
                cleanLatch.countDown();
            }
        });

        long startTime = System.currentTimeMillis();

        // Запускаем потоки
        searchThread.start();
        cleanThread.start();

        try {
            cleanLatch.await(); // Ждём завершения очистки
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        long endTime = System.currentTimeMillis();

        // Статистика в main
        System.out.println("\n=== СТАТИСТИКА В MAIN ===");
        System.out.println("Найдено файлов со словом '" + searchWord + "': " + filesFound.get());
        System.out.println("Удалено уникальных запрещённых слов: " + forbiddenWordsRemoved.get());
        System.out.println("Всего замен: " + totalReplacements.get());
        System.out.println("Файл объединения: " + mergedFile);
        System.out.println("Финальный файл: " + finalFile);
        System.out.println("Время выполнения: " + (endTime - startTime) + " мс");
    }
}